#!/bin/bash
# ============================================================
# إعداد مشروع iOS لتطبيق "بيننا" — يُنفّذ على macOS
# ============================================================
set -e

BUNDLE_ID="com.baynana.app"   # ← غيّره لمعرّفك الخاص

echo "🔍 فحص البيئة..."
flutter --version || { echo "❌ Flutter غير مثبت"; exit 1; }

echo ""
echo "📦 1/6 — تحديث الحزم..."
flutter pub get

echo ""
echo "📱 2/6 — إنشاء مجلدات المنصات..."
flutter create . --platforms=ios,android --org com.baynana --project-name baynana

echo ""
echo "🔥 3/6 — إعداد Firebase..."
echo "   إذا لم تكن ثبّت الأدوات:"
echo "   dart pub global activate flutterfire_cli"
echo "   npm install -g firebase-tools && firebase login"
read -p "   اضغط Enter لتشغيل flutterfire configure..."
flutterfire configure --ios-bundle-id="$BUNDLE_ID"

echo ""
echo "⚙️  4/6 — تطبيق إعدادات iOS..."
# AppDelegate
if [ -f ios_config/AppDelegate.swift ]; then
  cp ios_config/AppDelegate.swift ios/Runner/AppDelegate.swift
  echo "   ✅ AppDelegate.swift"
fi
# Entitlements
if [ -f ios_config/Runner.entitlements ]; then
  cp ios_config/Runner.entitlements ios/Runner/Runner.entitlements
  echo "   ✅ Runner.entitlements"
fi
echo "   ⚠️  أضف مفاتيح Info.plist يدويًا من: ios_config/Info.plist.additions.xml"

echo ""
echo "🎨 5/6 — توليد الأيقونات..."
bash tool/generate_icons.sh || echo "   ⚠️  تخطي (لا توجد أيقونة بعد)"

echo ""
echo "🧹 6/6 — تنظيف وبناء..."
cd ios && pod install --repo-update && cd ..
flutter clean && flutter pub get

echo ""
echo "✅ انتهى الإعداد!"
echo ""
echo "الخطوات المتبقية في Xcode (افتح ios/Runner.xcworkspace):"
echo "  1. Signing & Capabilities → اختر فريقك"
echo "  2. + Capability → Push Notifications"
echo "  3. + Capability → Background Modes → فعّل:"
echo "     • Remote notifications"
echo "     • Background fetch"
echo "  4. أضف مفاتيح Info.plist من ios_config/"
echo "  5. تأكد أن Deployment Target = iOS 13.0 أو أعلى"
