#!/bin/bash
# ============================================================
# توليد أيقونات iOS بكل المقاسات من صورة واحدة
# المتطلبات: macOS (يستخدم sips المدمج)
#
# الاستخدام:
#   1. ضع أيقونتك بمقاس 1024×1024 في: assets/icon/app_icon.png
#      (بدون شفافية — Apple ترفض الأيقونات الشفافة)
#   2. bash tool/generate_icons.sh
# ============================================================

SRC="assets/icon/app_icon.png"
DEST="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SRC" ]; then
  echo "❌ لم أجد الأيقونة في $SRC"
  echo "   ضع صورة 1024×1024 بهذا المسار وأعد المحاولة"
  exit 1
fi

mkdir -p "$DEST"

# المقاسات المطلوبة لـ iOS
declare -a sizes=(
  "20:Icon-App-20x20@1x"
  "40:Icon-App-20x20@2x"
  "60:Icon-App-20x20@3x"
  "29:Icon-App-29x29@1x"
  "58:Icon-App-29x29@2x"
  "87:Icon-App-29x29@3x"
  "40:Icon-App-40x40@1x"
  "80:Icon-App-40x40@2x"
  "120:Icon-App-40x40@3x"
  "120:Icon-App-60x60@2x"
  "180:Icon-App-60x60@3x"
  "76:Icon-App-76x76@1x"
  "152:Icon-App-76x76@2x"
  "167:Icon-App-83.5x83.5@2x"
  "1024:Icon-App-1024x1024@1x"
)

for entry in "${sizes[@]}"; do
  size="${entry%%:*}"
  name="${entry##*:}"
  sips -z "$size" "$size" "$SRC" --out "$DEST/$name.png" > /dev/null 2>&1
  echo "✅ $name.png (${size}×${size})"
done

echo ""
echo "🎉 تم توليد جميع الأيقونات في $DEST"
echo "   افتح Xcode وتأكد أن AppIcon مكتملة بدون خانات فارغة"
