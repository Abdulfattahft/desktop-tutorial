const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const REGION = "us-central1";
const COINS_PER_GAME = 15;
const LEVEL_THRESHOLDS = [
  0, 100, 250, 500, 900, 1500, 2500, 4000, 6000, 9000,
];
const GAME_TYPES = new Set([
  "knowMe",
  "whoKnows",
  "wouldYouRather",
  "truth",
  "dares",
  "guess",
  "wheel",
]);

function levelForPoints(points) {
  let level = 1;
  for (let index = 0; index < LEVEL_THRESHOLDS.length; index += 1) {
    if (points >= LEVEL_THRESHOLDS[index]) level = index + 1;
  }
  return level;
}

function dateKeyInRiyadh(date) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Riyadh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function dayNumber(dateKey) {
  return Math.floor(Date.parse(`${dateKey}T00:00:00Z`) / 86400000);
}

function nextStreak(currentStreak, lastPlayedAt, now) {
  if (!lastPlayedAt) return 1;

  const today = dateKeyInRiyadh(now);
  const previous = dateKeyInRiyadh(lastPlayedAt);
  const difference = dayNumber(today) - dayNumber(previous);

  if (difference <= 0) return currentStreak > 0 ? currentStreak : 1;
  if (difference === 1) return currentStreak + 1;
  return 1;
}

function requireString(value, field) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} مطلوب`);
  }
  return value.trim();
}

const finishGame = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولًا");
    }

    const data = request.data || {};
    const coupleId = requireString(data.coupleId, "coupleId");
    const gameType = requireString(data.gameType, "gameType");
    const fromRound = Number(data.fromRound);

    if (!GAME_TYPES.has(gameType)) {
      throw new HttpsError("invalid-argument", "نوع اللعبة غير صالح");
    }
    if (!Number.isInteger(fromRound) || fromRound < 0) {
      throw new HttpsError("invalid-argument", "رقم الجولة غير صالح");
    }

    const callerUid = request.auth.uid;
    const coupleRef = db.collection("couples").doc(coupleId);
    const sessionRef = coupleRef.collection("sessions").doc(gameType);

    try {
      return await db.runTransaction(async (tx) => {
        const [coupleSnap, sessionSnap] = await Promise.all([
          tx.get(coupleRef),
          tx.get(sessionRef),
        ]);

        if (!coupleSnap.exists) {
          throw new HttpsError("not-found", "العلاقة غير موجودة");
        }
        if (!sessionSnap.exists) {
          throw new HttpsError("not-found", "جلسة اللعبة غير موجودة");
        }

        const couple = coupleSnap.data() || {};
        const session = sessionSnap.data() || {};
        const coupleUsers = Array.isArray(couple.userIds) ? couple.userIds : [];
        const playerIds = Array.isArray(session.playerIds) ? session.playerIds : [];

        if (!coupleUsers.includes(callerUid) || !playerIds.includes(callerUid)) {
          throw new HttpsError("permission-denied", "غير مصرح بإدارة هذه اللعبة");
        }

        const score = Math.max(0, Math.trunc(Number(session.score) || 0));
        if (session.status === "finished") {
          return {
            status: "already-finished",
            score,
            coinsPerPlayer: COINS_PER_GAME,
          };
        }

        if (session.status !== "playing" || session.gameType !== gameType) {
          throw new HttpsError("failed-precondition", "حالة اللعبة غير صالحة");
        }

        const rounds = Array.isArray(session.rounds) ? session.rounds : [];
        const currentRound = Number(session.currentRound);
        if (!Number.isInteger(currentRound)) {
          throw new HttpsError("failed-precondition", "رقم الجولة الحالي غير صالح");
        }
        if (currentRound !== fromRound) {
          if (currentRound > fromRound) {
            return {
              status: "already-advanced",
              currentRound,
              score,
              coinsPerPlayer: 0,
            };
          }
          throw new HttpsError(
            "failed-precondition",
            "رقم الجولة المرسل أحدث من جلسة اللعبة"
          );
        }
        if (rounds.length === 0 || currentRound >= rounds.length) {
          throw new HttpsError("failed-precondition", "بيانات الجولات غير صالحة");
        }

        const answers = rounds[currentRound] && rounds[currentRound].answers;
        const completedByAllPlayers =
          answers &&
          typeof answers === "object" &&
          playerIds.length >= 2 &&
          playerIds.every((uid) =>
            Object.prototype.hasOwnProperty.call(answers, uid)
          );

        if (!completedByAllPlayers) {
          throw new HttpsError(
            "failed-precondition",
            "يجب أن يجيب الطرفان قبل المتابعة"
          );
        }

        if (
          playerIds.length !== 2 ||
          !playerIds.every((uid) => coupleUsers.includes(uid))
        ) {
          throw new HttpsError(
            "failed-precondition",
            "بيانات اللاعبين غير متطابقة مع العلاقة"
          );
        }

        const isLastRound = currentRound === rounds.length - 1;
        if (!isLastRound) {
          tx.update(sessionRef, { currentRound: currentRound + 1 });
          return {
            status: "advanced",
            currentRound: currentRound + 1,
            score,
            coinsPerPlayer: 0,
          };
        }

        const userRefs = playerIds.map((uid) => db.collection("users").doc(uid));
        const userSnaps = await Promise.all(userRefs.map((ref) => tx.get(ref)));
        if (userSnaps.some((snapshot) => !snapshot.exists)) {
          throw new HttpsError("failed-precondition", "حساب أحد اللاعبين غير موجود");
        }

        const now = new Date();
        const oldTotal = Math.trunc(Number(couple.totalPoints) || 0);
        const newTotal = oldTotal + score;
        const currentStreak = Math.trunc(Number(couple.streak) || 0);
        const lastPlayedAt = couple.lastPlayedAt
          ? couple.lastPlayedAt.toDate()
          : null;
        const streak = nextStreak(currentStreak, lastPlayedAt, now);
        const createdAtMillis = session.createdAt?.toMillis?.() || "legacy";
        const historyRef = coupleRef
          .collection("gameHistory")
          .doc(`${gameType}_${createdAtMillis}`);

        tx.update(sessionRef, {
          status: "finished",
          finishedAt: FieldValue.serverTimestamp(),
          rewardGrantedAt: FieldValue.serverTimestamp(),
          finishedBy: callerUid,
        });

        tx.update(coupleRef, {
          totalPoints: newTotal,
          level: levelForPoints(newTotal),
          streak,
          lastPlayedAt: FieldValue.serverTimestamp(),
          gamesPlayedTotal: FieldValue.increment(1),
        });

        for (const userRef of userRefs) {
          tx.update(userRef, {
            points: FieldValue.increment(score),
            coins: FieldValue.increment(COINS_PER_GAME),
          });
        }

        tx.set(historyRef, {
          gameTypeName: gameType,
          score,
          playedAt: FieldValue.serverTimestamp(),
          playerIds,
          completedBy: callerUid,
          sessionCreatedAt: session.createdAt || null,
        });

        return {
          status: "finished",
          score,
          coinsPerPlayer: COINS_PER_GAME,
          totalPoints: newTotal,
          level: levelForPoints(newTotal),
          streak,
        };
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("finishGame failed", {
        coupleId,
        gameType,
        fromRound,
        callerUid,
        error,
      });
      throw new HttpsError(
        "internal",
        "تعذر تحديث اللعبة الآن. حاول مرة أخرى"
      );
    }
  }
);

module.exports = {
  finishGame,
  _test: {
    dateKeyInRiyadh,
    levelForPoints,
    nextStreak,
  },
};
