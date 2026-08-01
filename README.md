# بيننا | Baynana Web

نسخة Flutter Web من مشروع **بيننا** للأزواج والمخطوبين، مع الحفاظ على بنية المشروع الحالية قدر الإمكان:

- Firebase
- MVVM
- Features
- Repositories
- RTL Arabic
- Responsive Web UI

## المزايا

- الحسابات وتسجيل الدخول
- ربط الشريكين
- الألعاب والتحديات
- الذكريات ورفع الصور
- متجر الهدايا
- الإشعارات
- المساعد الذكي عبر Cloud Functions

## التشغيل محليًا

```bash
flutter config --enable-web
flutter pub get
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
```

## البناء والنشر

```bash
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET

firebase deploy --only hosting
```

## الأمان

- لا تضع مفتاح مزود الذكاء الاصطناعي داخل Flutter Web.
- استخدم Cloud Functions لاستدعاء مزود الذكاء الاصطناعي.
- راجع قواعد Firestore وStorage قبل النشر العام.

## حالة المشروع

هذا الفرع مخصص لنسخة `baynana-web-ready`. يلزم رفع محتويات الحزمة إلى جذر الفرع، مع عدم رفع أي أسرار أو مفاتيح خاصة.
