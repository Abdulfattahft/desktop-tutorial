# بيننا 💕

تطبيق للمخطوبين والأزواج في مدن مختلفة — ألعاب، تحديات، ذكريات.

## هيكل المشروع (Clean Architecture + MVVM)

```
lib/
├── main.dart                  ← نقطة الانطلاق + تهيئة Firebase
├── app.dart                   ← MaterialApp، الثيمات، اللغات، RTL
├── firebase_options.dart      ← يتولد تلقائيًا (flutterfire configure)
│
├── core/                      ← كل ما هو مشترك بين الميزات
│   ├── theme/                 ← الألوان والثيم (فاتح/ليلي)
│   ├── constants/             ← الثوابت (Firestore، النقاط، المستويات)
│   ├── routing/               ← go_router وأسماء المسارات
│   ├── services/              ← خدمات عامة (إشعارات، تخزين...)
│   ├── utils/                 ← دوال مساعدة
│   └── widgets/               ← عناصر واجهة مشتركة
│
├── features/                  ← كل ميزة مستقلة بثلاث طبقات
│   ├── auth/                  ← تسجيل الدخول والحساب
│   │   ├── data/              ← models + repositories (تتعامل مع Firebase)
│   │   ├── domain/            ← entities + usecases (منطق العمل النقي)
│   │   └── presentation/      ← screens + widgets + viewmodels
│   ├── linking/               ← ربط الشريكين برمز الدعوة
│   ├── home/                  ← الصفحة الرئيسية والعداد التنازلي
│   ├── games/                 ← الألعاب السبع
│   ├── challenges/            ← التحديات اليومية
│   ├── memories/              ← الذكريات والـ Timeline
│   ├── points/                ← النقاط والمستويات والشارات
│   ├── gifts/                 ← الهدايا الافتراضية
│   ├── notifications/         ← FCM
│   └── settings/              ← الإعدادات والوضع الليلي
│
└── l10n/                      ← ملفات الترجمة (عربي الآن، إنجليزي لاحقًا)
```

## خطوات إعداد Firebase (مرة واحدة)

1. أنشئ مشروعًا في [Firebase Console](https://console.firebase.google.com)
2. فعّل: **Authentication (Email/Password)** + **Firestore** + **Storage** + **Cloud Messaging**
3. من الطرفية داخل مجلد المشروع:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. سيتولد ملف `lib/firebase_options.dart` — فعّل السطر الخاص به في `main.dart`
5. ثم:

```bash
flutter pub get
flutter run
```

## الإطلاق

- خطوات iOS و TestFlight كاملة: **[LAUNCH.md](LAUNCH.md)**
- خطة الاختبار: **[TESTING.md](TESTING.md)**
- ملفات إعداد iOS: `ios_config/`
- سكربتات: `tool/setup_ios.sh` و `tool/generate_icons.sh`

## المراحل

- [x] المرحلة 1: الهيكل + الثيم + التوجيه + تهيئة Firebase
- [x] المرحلة 1.5: Splash + Onboarding (3 صفحات، أول تشغيل فقط)
- [x] المرحلة 2: تسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور
- [x] المرحلة 3: ربط الشريكين (Invite Code) — الملف الشخصي مع الإعدادات لاحقًا
- [x] المرحلة 4: الصفحة الرئيسية الكاملة (عداد، مستوى، ستريك، آخر ظهور)
- [x] المرحلة 6: التحديات اليومية والأسبوعية (توليد حتمي + مكافآت)
- [x] المرحلة 5: الألعاب السبع كاملة بمحرك جلسات لحظي
- [x] المرحلة 7: الذكريات (Timeline + صور + إعجاب وتعليقات)
- [ ] المرحلة 8: النقاط والمستويات والشارات
- [x] المرحلة 8: الهدايا (كتالوج ديناميكي + شروط فتح + سجل وإحصائيات)
- [x] المرحلة 9: الإشعارات (FCM + مركز إشعارات + Cloud Functions)
- [x] المرحلة 10: الذكاء الاصطناعي (طبقة مجردة + مزودان)

## نسخة Web
تمت إضافة دعم Flutter Web مع Firebase Hosting ورفع صور متوافق مع المتصفح وتصميم متجاوب أساسي وحماية Routes وصفحة 404. ابدأ من `WEB_SETUP.md`، وراجع `WEB_CHANGES.md` و`WEB_TESTING.md`.
