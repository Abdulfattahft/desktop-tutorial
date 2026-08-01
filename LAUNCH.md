# دليل إطلاق "بيننا" على App Store 🚀

---

## المتطلبات قبل البدء

| المتطلب | ملاحظات |
|---|---|
| جهاز Mac | إلزامي — Xcode لا يعمل على Windows/Linux |
| Xcode 15+ | من App Store مجانًا |
| حساب Apple Developer | **99$ سنويًا** — [developer.apple.com/programs](https://developer.apple.com/programs) |
| Flutter مثبت | `flutter doctor` بدون أخطاء |
| مشروع Firebase | مُعد بالفعل من المراحل السابقة |

> ⚠️ اشتراك Apple Developer قد يستغرق **24-48 ساعة** للتفعيل. ابدأ به الآن.

---

## المرحلة 1 — إنشاء مشروع iOS

```bash
cd baynana
bash tool/setup_ios.sh
```

السكربت ينفذ: `flutter pub get` → `flutter create` → `flutterfire configure` → نسخ ملفات الإعداد → توليد الأيقونات → `pod install`.

**يدويًا بعده:** انسخ مفاتيح `ios_config/Info.plist.additions.xml` داخل `ios/Runner/Info.plist`.

---

## المرحلة 2 — إعدادات Xcode

افتح **`ios/Runner.xcworkspace`** (وليس `.xcodeproj`).

### 2.1 التوقيع
`Runner` → `Signing & Capabilities`:
- ✅ Automatically manage signing
- Team: اختر فريقك
- Bundle Identifier: `com.baynana.app` (يجب أن يكون **فريدًا عالميًا** — استخدم نطاقك)

### 2.2 القدرات (Capabilities)
اضغط **+ Capability** وأضف:
1. **Push Notifications**
2. **Background Modes** → فعّل:
   - ✅ Remote notifications
   - ✅ Background fetch

### 2.3 الإصدار
`General` → Minimum Deployments → **iOS 13.0**

---

## المرحلة 3 — ربط APNs بـ Firebase (بدونها لا تصل الإشعارات)

### 3.1 إنشاء مفتاح APNs
1. [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**
2. **Keys** → زر **+**
3. الاسم: `Baynana APNs Key` → ✅ **Apple Push Notifications service (APNs)**
4. **Continue** → **Register** → **Download** (ملف `.p8`)
5. ⚠️ **الملف يُحمَّل مرة واحدة فقط** — احفظه في مكان آمن
6. سجّل: **Key ID** (من الصفحة) و **Team ID** (أعلى يمين الحساب)

### 3.2 رفعه إلى Firebase
Firebase Console → ⚙️ **Project Settings** → **Cloud Messaging** → قسم **Apple app configuration**:
- **APNs Authentication Key** → Upload
- ارفع ملف `.p8` + أدخل Key ID و Team ID

---

## المرحلة 4 — الأيقونة وشاشة البداية

### الأيقونة
1. صمّم أيقونة **1024×1024 PNG بدون شفافية** (Apple ترفض الشفافة)
2. ضعها في `assets/icon/app_icon.png`
3. `bash tool/generate_icons.sh`

### شاشة البداية
راجع `ios_config/LaunchScreen.storyboard.notes.md` — الطريقة اليدوية أو `flutter_native_splash`.

---

## المرحلة 5 — App Store Connect

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**

| الحقل | القيمة |
|---|---|
| Platform | iOS |
| Name | بيننا |
| Primary Language | Arabic |
| Bundle ID | اختر `com.baynana.app` |
| SKU | `baynana-001` (أي معرّف داخلي) |

### معلومات مطلوبة للمراجعة
- **Category:** Lifestyle (فرعية: Social Networking)
- **Age Rating:** أجب على الاستبيان — التطبيق للأزواج، اختر 12+ أو 17+ حسب محتوى "الصراحة"
- **Privacy Policy URL:** **إلزامي** — تحتاج صفحة سياسة خصوصية منشورة (يمكن استضافتها مجانًا على GitHub Pages أو Notion)
- **Data Collection:** أفصح عن: البريد الإلكتروني، الصور، بيانات الاستخدام
- **Screenshots:** مطلوبة لمقاسي 6.7" و 6.5" (3 صور على الأقل لكل مقاس)

---

## المرحلة 6 — بناء نسخة Release ورفعها

### 6.1 رقم الإصدار
في `pubspec.yaml`:
```yaml
version: 1.0.0+1
#        ↑     ↑
#        │     └── build number — يجب زيادته مع كل رفع
#        └── version name — يظهر للمستخدمين
```

### 6.2 البناء
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

الناتج: `build/ios/archive/Runner.xcarchive`

### 6.3 الرفع — طريقتان

**أ) عبر Xcode (الأسهل):**
```bash
open build/ios/archive/Runner.xcarchive
```
→ **Distribute App** → **App Store Connect** → **Upload** → Next حتى النهاية

**ب) عبر سطر الأوامر:**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --username "بريدك@apple.id" \
  --password "app-specific-password"
```
> كلمة المرور الخاصة بالتطبيق تُنشأ من [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords

---

## المرحلة 7 — TestFlight

1. بعد الرفع، انتظر **10-30 دقيقة** حتى تنتهي المعالجة (يصلك إيميل)
2. App Store Connect → تطبيقك → تبويب **TestFlight**
3. إذا ظهر **Missing Compliance:** اضغط عليه واختر "لا يستخدم تشفيرًا" (المفتاح `ITSAppUsesNonExemptEncryption` موجود في Info.plist لتفادي هذا)

### اختبار داخلي (فوري، بدون مراجعة)
- **Internal Testing** → **+** → أنشئ مجموعة
- أضف حتى **100** مختبر (يجب أن يكونوا أعضاء في حسابك)
- اختر البناء → يصلهم فورًا

### اختبار خارجي (يحتاج مراجعة 24-48 ساعة)
- **External Testing** → أنشئ مجموعة → أضف حتى **10,000** مختبر بالبريد
- أدخل **What to Test** (بالعربي) → **Submit for Review**

### تثبيت التطبيق
المختبر يحمّل تطبيق **TestFlight** من App Store، ويفتح الدعوة من بريده.

---

## المرحلة 8 — النشر النهائي

1. App Store Connect → **App Store** → **+ Version**
2. املأ: الوصف، الكلمات المفتاحية، لقطات الشاشة، رابط الدعم
3. اختر البناء من TestFlight
4. **Add for Review** → **Submit**
5. المراجعة تستغرق عادة **24-72 ساعة**

### أسباب رفض شائعة — تجنّبها
| السبب | الحل |
|---|---|
| لا توجد سياسة خصوصية | انشر صفحة وأضف رابطها |
| حساب تجريبي مفقود | أنشئ حسابين مرتبطين وضع بياناتهما في "App Review Information" |
| وصف أذونات غير واضح | نصوص `Info.plist` عندنا مفصّلة بالعربي ✅ |
| التطبيق ينهار عند المراجعة | اختبر على جهاز حقيقي أولًا |
| ميزات غير مكتملة | تأكد أن كل زر يعمل (زر "الإعدادات" في الرئيسية ما زال "قريبًا") |

> ⚠️ **مهم:** وفّر لفريق المراجعة **حسابين مرتبطين مسبقًا** مع رمز الدعوة، وإلا لن يتمكنوا من تجربة التطبيق (لأنه يحتاج شريكًا).

---

## قائمة التحقق النهائية ✅

### الشاشات — كلها مكتملة ✅
- [ ] كل زر في الرئيسية يفتح شاشة فعّالة (لا يوجد "قريبًا")
- [ ] الإعدادات: الحساب، العلاقة، الإشعارات، المساعد، المظهر، البيانات، القانوني
- [ ] تعديل الملف الشخصي (الاسم + الصورة) يعمل
- [ ] **حذف الحساب يعمل** — إلزامي لموافقة Apple
- [ ] فصل العلاقة بموافقة الطرفين يعمل
- [ ] الوضع الليلي اليدوي يغيّر التطبيق كله فورًا

### الكود
- [ ] `flutter analyze` بدون أخطاء
- [ ] لا `print()` ولا `TODO` في كود الإنتاج
- [ ] `AIConfig.activeProviderId` = `'cloud_function'` (وليس `mock`)
- [ ] `AIConfig.cloudFunctionEndpoint` يحمل الرابط الحقيقي
- [ ] `firebase_options.dart` مولّد وسطره مفعّل في `main.dart`

### Firebase
- [ ] Authentication → Email/Password مفعّل
- [ ] Firestore Rules منشورة (`firestore.rules`)
- [ ] Storage Rules منشورة (`storage.rules`)
- [ ] Cloud Functions منشورة: `firebase deploy --only functions`
- [ ] `AI_API_KEY` مضبوط كـ secret
- [ ] APNs Key مرفوع في Cloud Messaging
- [ ] **Firestore في وضع Production** (وليس Test Mode المؤقت)

### iOS
- [ ] Bundle ID فريد ومطابق في Xcode و Firebase
- [ ] Push Notifications + Background Modes مفعّلة
- [ ] كل مفاتيح `Info.plist` مضافة
- [ ] `aps-environment` = `production` في نسخة Release
- [ ] الأيقونة مكتملة بكل المقاسات
- [ ] شاشة البداية بألوان الهوية

### القانوني ⚠️
- [ ] **مراجعة النصوص القانونية مع مستشار قانوني** (المسودة في `legal_texts.dart` نقطة انطلاق فقط)
- [ ] نشر سياسة الخصوصية على رابط عام (النسخة داخل التطبيق لا تكفي Apple)
- [ ] تحديث بريد التواصل في نص السياسة

### App Store Connect
- [ ] سياسة الخصوصية منشورة ورابطها مضاف
- [ ] لقطات شاشة لمقاسي 6.7" و 6.5"
- [ ] الوصف والكلمات المفتاحية بالعربي
- [ ] Age Rating مكتمل
- [ ] **حساب تجريبي مرتبط** في App Review Information
- [ ] إفصاح جمع البيانات مكتمل

### الاختبار
- [ ] جميع بنود `TESTING.md` مجتازة
- [ ] اختُبر على جهاز iPhone حقيقي (وليس محاكي فقط)
- [ ] اختُبر على شاشة صغيرة (iPhone SE)
- [ ] الإشعارات تصل والتطبيق مغلق
