# تشغيل نسخة بيننا Web

## 1. المتطلبات
- Flutter stable مع Dart 3.4 أو أحدث.
- Firebase CLI وFlutterFire CLI.
- مشروع Firebase مفعل فيه Authentication وFirestore وStorage وFunctions.

## 2. تفعيل Web وإنزال الحزم
```bash
flutter config --enable-web
flutter pub get
flutter doctor
```

## 3. إعداد Firebase
من Firebase Console أضف Web App ثم انسخ قيم الإعداد. شغّل محليًا بهذه القيم:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=FIREBASE_MEASUREMENT_ID=...
```

يمكن بدلًا من ذلك استخدام `flutterfire configure` واستبدال ملف الخيارات الحالي بملف FlutterFire المولد. لا تضع مفتاح مزود الذكاء الاصطناعي في Flutter؛ يبقى داخل Functions Secret فقط.

## 4. Firebase Authentication
فعّل Email/Password، ثم أضف نطاقات التشغيل والنشر إلى Authentication > Settings > Authorized domains، مثل `localhost` ونطاق Firebase Hosting.

## 5. Web Push اختياري
1. أنشئ Web Push certificate من Firebase Cloud Messaging وانسخ VAPID key.
2. انسخ `web/firebase-messaging-sw.js.example` إلى `web/firebase-messaging-sw.js` واستبدل القيم.
3. شغّل مع `--dart-define=FIREBASE_WEB_VAPID_KEY=...`.
4. Web Push يحتاج HTTPS، ولا يعمل في وضع التصفح الخاص ببعض المتصفحات.

## 6. Cloud Functions والذكاء الاصطناعي
```bash
cd functions
npm install
cd ..
firebase functions:secrets:set AI_API_KEY
firebase deploy --only functions
```
حدّث `config/ai.endpoint` في Firestore إلى رابط `aiAssistant`. طلبات AI تمر عبر Function مع Firebase ID Token، ولا يوجد API Key في الواجهة.

## 7. البناء والنشر
```bash
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...

cp .firebaserc.example .firebaserc
# استبدل YOUR_FIREBASE_PROJECT_ID
firebase deploy --only hosting
```

`firebase.json` يحتوي SPA rewrite حتى تعمل الروابط المباشرة مثل `/games` و`/memories`.
