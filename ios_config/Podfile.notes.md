# ملاحظات Podfile

بعد `flutter create`، افتح `ios/Podfile` وتأكد من:

## 1. الحد الأدنى لإصدار iOS
في أول سطر غير معلّق:
```ruby
platform :ios, '13.0'
```
Firebase يتطلب iOS 13 على الأقل في الإصدارات الحديثة.

## 2. إذا ظهرت أخطاء بناء، أضف في نهاية الملف:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # أذونات image_picker — تمنع أخطاء الترجمة
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

## 3. عند تغيير أي حزمة:
```bash
cd ios
pod install --repo-update
cd ..
```

## 4. إذا فشل البناء بعد تحديث الحزم:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean && flutter pub get
```
