# تغييرات نسخة Web

## ملفات جديدة
- `web/index.html`, `manifest.json`, الأيقونات وfavicon.
- `lib/core/config/web_firebase_options.dart` لإعداد Firebase عبر dart-defines.
- `lib/core/widgets/responsive_page_frame.dart` لضبط عرض الجوال والتابلت واللابتوب والشاشات الكبيرة.
- `lib/core/presentation/screens/not_found_screen.dart` لصفحة 404.
- `firebase.json` و`.firebaserc.example` للنشر.
- `WEB_SETUP.md`, `WEB_TESTING.md`.

## ملفات معدلة
- `main.dart`: Firebase Web، Path URL strategy، وعدم تسجيل background handler الخاص بالجوال على Web.
- `app.dart`: إطار Responsive عام يحافظ على RTL والثيم الحالي.
- `app_router.dart`: صفحة خطأ وحماية Routes الأساسية.
- الذكريات والملف الشخصي: استبدال `dart:io/File/putFile` بـ `XFile/readAsBytes/putData` لدعم Web والجوال.
- Push Notification service: دعم VAPID key عبر dart-define.
- `pubspec.yaml`: إضافة `flutter_web_plugins` من Flutter SDK.

## توافق الحزم
الحزم الأساسية المستخدمة لديها دعم Web حاليًا: Firebase Core/Auth/Firestore/Storage/Messaging، Provider، GoRouter، Image Picker، Shared Preferences، HTTP، Share Plus، Google Fonts وCached Network Image. تمت إزالة الاعتماد المباشر على `dart:io` من مسارات الصور. Web Push بقي اختياريًا لأنه يحتاج service worker وVAPID وإذن المستخدم.

## ملاحظات معمارية
لم تتغير بنية Features/MVVM/Repositories أو أسماء Collections وقاعدة Firestore. التعديل ركز على طبقة المنصة والعرض، لذلك تبقى نسخة Mobile قابلة للتطوير من القاعدة نفسها.
