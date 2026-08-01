# شاشة البداية الأصلية (Native Splash)

شاشة `SplashScreen` في Flutter تظهر **بعد** تحميل محرك Flutter.
قبلها تظهر شاشة iOS الأصلية — نجعلها بنفس الهوية لتفادي وميض أبيض.

## الطريقة (في Xcode):

1. افتح `ios/Runner/Assets.xcassets` → `LaunchImage`
2. احذف الصور الافتراضية وضع صورة شعارك (قلب بتدرج وردي-ذهبي على خلفية `#FFFDFA`)
   - `LaunchImage.png` — 200×200
   - `LaunchImage@2x.png` — 400×400
   - `LaunchImage@3x.png` — 600×600
3. افتح `ios/Runner/Base.lproj/LaunchScreen.storyboard`
4. اختر الـ View الرئيسي → Background → Custom → أدخل:
   - Red: 255, Green: 253, Blue: 250 (نفس `AppColors.background`)
5. تأكد أن `LaunchImage` في المنتصف بقيود Center X و Center Y

## بديل أسهل — حزمة flutter_native_splash:

```yaml
# في pubspec.yaml تحت dev_dependencies
dev_dependencies:
  flutter_native_splash: ^2.4.1

# ثم في نهاية pubspec.yaml
flutter_native_splash:
  color: "#FFFDFA"
  image: assets/icon/splash_logo.png
  color_dark: "#1E1A19"
  ios: true
  android: true
  ios_content_mode: center
```

ثم:
```bash
flutter pub get
dart run flutter_native_splash:create
```
