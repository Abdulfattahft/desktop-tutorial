/**
 * Cloud Functions لتطبيق "بيننا"
 *
 * 1) sendPushOnNotification: عند إنشاء إشعار في Firestore ترسل Push
 *    (مع احترام تفضيلات المستخدم وحالة نشاطه)
 * 2) streakWarningScheduler: تذكير يومي قبل انكسار الستريك
 * 3) weddingCountdownScheduler: تذكير عند اقتراب موعد الزواج
 * 4) sendCampaign: إشعارات جماعية/موسمية (قابل للاستدعاء)
 *
 * النشر:
 *   cd functions && npm install
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// المستخدم يُعتبر نشطًا إذا ظهر خلال آخر دقيقتين
const ACTIVE_WINDOW_MS = 2 * 60 * 1000;

/**
 * إرسال Push عند إنشاء إشعار
 */
exports.sendPushOnNotification = onDocumentCreated(
  { document: "users/{userId}/notifications/{notifId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notif = snap.data();
    const userId = event.params.userId;

    // 1) بيانات المستخدم (الرمز + التفضيلات + آخر ظهور)
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;
    const user = userDoc.data();

    // 2) احترام تفضيلات الفئة (غير المذكورة = مفعّلة)
    const category = notif.category || "system";
    const prefs = user.notificationPrefs || {};
    if (prefs[category] === false) {
      console.log(`الفئة ${category} معطّلة للمستخدم ${userId}`);
      return snap.ref.update({ pushSent: false, pushSkipped: "category_disabled" });
    }

    // 3) إذا كان المستخدم نشطًا الآن، نكتفي بالإشعار داخل التطبيق
    const lastActive = user.lastActive ? user.lastActive.toMillis() : 0;
    if (Date.now() - lastActive < ACTIVE_WINDOW_MS) {
      console.log(`المستخدم ${userId} نشط — تخطي Push`);
      return snap.ref.update({ pushSent: false, pushSkipped: "user_active" });
    }

    // 4) الرموز (دعم أجهزة متعددة)
    const tokens = user.fcmTokens && user.fcmTokens.length
      ? user.fcmTokens
      : (user.fcmToken ? [user.fcmToken] : []);
    if (!tokens.length) return;

    // 5) عدد غير المقروء للشارة
    const unreadSnap = await db
      .collection("users").doc(userId)
      .collection("notifications")
      .where("isRead", "==", false).get();

    const message = {
      tokens,
      notification: { title: notif.title, body: notif.body },
      data: {
        type: notif.type || "system",
        actionRoute: notif.actionRoute || "",
        notifId: snap.id,
        ...(notif.data
          ? Object.fromEntries(
              Object.entries(notif.data).map(([k, v]) => [k, String(v)])
            )
          : {}),
      },
      apns: {
        payload: {
          aps: {
            sound: notif.priority === "high" ? "default" : undefined,
            badge: unreadSnap.size,
            "content-available": 1,
          },
        },
      },
      android: {
        priority: notif.priority === "high" ? "high" : "normal",
        notification: { channelId: "baynana_default", sound: "default" },
      },
    };

    try {
      const res = await messaging.sendEachForMulticast(message);

      // تنظيف الرموز غير الصالحة
      const invalid = [];
      res.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error && r.error.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            invalid.push(tokens[i]);
          }
        }
      });
      if (invalid.length) {
        await userDoc.ref.update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalid),
        });
      }

      return snap.ref.update({
        pushSent: res.successCount > 0,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      console.error("فشل إرسال Push:", err);
      return snap.ref.update({ pushSent: false, pushError: String(err) });
    }
  }
);

/**
 * تذكير الستريك — يوميًا 8 مساءً بتوقيت السعودية
 */
exports.streakWarningScheduler = onSchedule(
  { schedule: "0 20 * * *", timeZone: "Asia/Riyadh", region: "us-central1" },
  async () => {
    const today = new Date();
    const dayKey = today.toISOString().slice(0, 10);
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    const couples = await db.collection("couples").where("streak", ">", 0).get();

    for (const doc of couples.docs) {
      const couple = doc.data();
      const lastPlayed = couple.lastPlayedAt ? couple.lastPlayedAt.toDate() : null;
      // لعبا اليوم؟ لا تذكير
      if (lastPlayed && lastPlayed >= startOfDay) continue;

      for (const uid of couple.userIds || []) {
        const ref = db.collection("users").doc(uid)
          .collection("notifications").doc(`streak_${dayKey}`);
        const existing = await ref.get();
        if (existing.exists) continue; // منع التكرار

        await ref.set({
          id: `streak_${dayKey}`,
          type: "streakWarning",
          category: "challenges",
          title: "ستريككما بخطر! 🔥",
          body: `${couple.streak} أيام متتالية… العبا لعبة اليوم قبل ما ينكسر`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          data: {},
          actionRoute: "/games",
          priority: "high",
          dedupeKey: `streak_${dayKey}`,
          pushSent: false,
        });
      }
    }
    console.log("انتهى فحص الستريك");
  }
);

/**
 * تذكير موعد الزواج — عند 100/50/30/14/7/3/1 يوم
 */
exports.weddingCountdownScheduler = onSchedule(
  { schedule: "0 10 * * *", timeZone: "Asia/Riyadh", region: "us-central1" },
  async () => {
    const milestones = [100, 50, 30, 14, 7, 3, 1];
    const now = new Date();

    const couples = await db.collection("couples")
      .where("weddingDate", ">", admin.firestore.Timestamp.fromDate(now)).get();

    for (const doc of couples.docs) {
      const couple = doc.data();
      const wedding = couple.weddingDate.toDate();
      const daysLeft = Math.ceil((wedding - now) / (1000 * 60 * 60 * 24));
      if (!milestones.includes(daysLeft)) continue;

      for (const uid of couple.userIds || []) {
        const ref = db.collection("users").doc(uid)
          .collection("notifications").doc(`wedding_${daysLeft}`);
        const existing = await ref.get();
        if (existing.exists) continue;

        await ref.set({
          id: `wedding_${daysLeft}`,
          type: "weddingCountdown",
          category: "occasions",
          title: `باقي ${daysLeft} يوم على زواجكما! 💍`,
          body: "العد التنازلي مستمر… استعدا للحظة الكبيرة",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          data: { daysLeft: String(daysLeft) },
          actionRoute: "/home",
          priority: "normal",
          dedupeKey: `wedding_${daysLeft}`,
          pushSent: false,
        });
      }
    }
  }
);

/**
 * إشعارات جماعية / حملات موسمية
 * تُستدعى من لوحة تحكم إدارية (تحقق من صلاحية المنادي)
 */
exports.sendCampaign = onCall({ region: "us-central1" }, async (request) => {
  const { title, body, actionRoute, adminKey } = request.data || {};

  // بديل بسيط: مفتاح إداري في إعدادات البيئة
  if (adminKey !== process.env.ADMIN_KEY) {
    throw new HttpsError("permission-denied", "غير مصرح");
  }
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "العنوان والنص مطلوبان");
  }

  const campaignId = `campaign_${Date.now()}`;
  const users = await db.collection("users").get();
  let batch = db.batch();
  let count = 0;

  for (const u of users.docs) {
    const ref = db.collection("users").doc(u.id)
      .collection("notifications").doc(campaignId);
    batch.set(ref, {
      id: campaignId,
      type: "campaign",
      category: "system",
      title, body,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      data: {},
      actionRoute: actionRoute || "/home",
      priority: "normal",
      dedupeKey: campaignId,
      pushSent: false,
    });
    count++;
    // Firestore يسمح بـ500 عملية لكل دفعة
    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  await batch.commit();
  return { sent: count };
});

/**
 * ===================== المساعد الذكي =====================
 * نقطة نهاية واحدة لكل مهام الذكاء الاصطناعي.
 * المفتاح يبقى سرًا على الخادم ولا يصل للتطبيق أبدًا.
 *
 * الإعداد:
 *   firebase functions:secrets set AI_API_KEY
 *   firebase deploy --only functions:aiAssistant
 *
 * لتغيير المزود: عدّل callProvider() فقط — التطبيق لا يتغير.
 */
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const AI_API_KEY = defineSecret("AI_API_KEY");

/** تعليمات النظام لكل مهمة */
function buildPrompt(task, context, language) {
  const lang = language === "en" ? "English" : "Arabic (Gulf dialect)";
  const base =
    `You are a warm, respectful relationship assistant for "بيننا", an app for ` +
    `engaged/married couples living apart. Reply in ${lang}. Keep content ` +
    `family-friendly and culturally appropriate for Saudi/Gulf users. ` +
    `Never include personal data. Be concise and warm.`;

  const tasks = {
    dateIdeas: `Suggest 3 creative long-distance date ideas. Return JSON: {"items": ["...", "...", "..."]}`,
    activitySuggestion: `Current hour is ${context.hour}. Suggest 2 activities fitting this time of day. Return JSON: {"items": ["...","..."]}`,
    gameSuggestion: `They played ${context.gamesPlayed || 0} games. Suggest 2 game ideas. Return JSON: {"items": ["...","..."]}`,
    challengeIdeas: `Suggest 3 daily couple challenges. Return JSON: {"items": ["...","...","..."]}`,
    giftSuggestion: `They have ${context.coins || 0} in-app coins. Suggest suitable virtual gifts. Return JSON: {"items": ["..."]}`,
    writeMessage: `Write a "${context.kind}" message with a "${context.tone}" tone${context.occasion ? ` for: ${context.occasion}` : ""}. 2-4 sentences. Return JSON: {"text": "..."}`,
    generateQuestions: `Generate 3 "${context.level}" couple questions. Avoid these: ${JSON.stringify(context.exclude || [])}. Return JSON: {"items": ["...","...","..."]}`,
    relationshipInsights: `Given these stats: ${JSON.stringify(context)}, write a short encouraging summary plus 3 improvement tips. Return JSON: {"text": "..."}`,
  };

  return { system: base, user: tasks[task] || tasks.dateIdeas };
}

/**
 * استدعاء المزود — غيّر هذه الدالة وحدها لتبديل المزود
 * أمثلة: Anthropic / OpenAI / Gemini
 */
async function callProvider(system, user, apiKey) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 1000,
      system: system + " Respond ONLY with valid JSON, no markdown fences.",
      messages: [{ role: "user", content: user }],
    }),
  });
  if (!res.ok) throw new Error(`Provider error ${res.status}`);
  const data = await res.json();
  const text = (data.content || [])
    .filter((b) => b.type === "text")
    .map((b) => b.text)
    .join("");
  return text.replace(/```json|```/g, "").trim();
}

exports.aiAssistant = onRequest(
  { secrets: [AI_API_KEY], region: "us-central1", cors: true },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    // التحقق من أن المستخدم مسجّل دخوله
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!idToken) return res.status(401).json({ error: "unauthorized" });
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      return res.status(401).json({ error: "invalid token" });
    }

    const { task, context = {}, language = "ar" } = req.body || {};
    if (!task) return res.status(400).json({ error: "task required" });

    try {
      const { system, user } = buildPrompt(task, context, language);
      const raw = await callProvider(system, user, AI_API_KEY.value());
      let parsed;
      try {
        parsed = JSON.parse(raw);
      } catch {
        parsed = { text: raw }; // احتياط لو لم يرجع JSON صالحًا
      }
      return res.json({
        items: parsed.items || [],
        text: parsed.text || null,
        extra: {},
      });
    } catch (err) {
      console.error("AI error:", err);
      return res.status(500).json({ error: "ai_failed" });
    }
  }
);
