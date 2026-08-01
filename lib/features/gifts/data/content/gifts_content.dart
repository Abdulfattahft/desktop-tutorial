import '../models/gift_models.dart';

/// الكتالوج الافتراضي — يُستخدم إذا كانت مجموعة giftCatalog في
/// Firestore فارغة. لإضافة هدايا جديدة بدون تحديث التطبيق:
/// أضف مستندات في giftCatalog من الـ Console بنفس الحقول
class GiftsContent {
  GiftsContent._();

  static final List<GiftCatalogItem> defaultCatalog = [
    // ===== ورود =====
    const GiftCatalogItem(id: 'rose_single', name: 'وردة حمراء', emoji: '🌹', description: 'وردة واحدة تقول الكثير', price: 50, category: GiftCategory.roses, rarity: GiftRarity.common, sortOrder: 1),
    const GiftCatalogItem(id: 'rose_bouquet', name: 'باقة ورد', emoji: '💐', description: 'باقة كاملة من الحب', price: 150, category: GiftCategory.roses, rarity: GiftRarity.rare, sortOrder: 2),
    const GiftCatalogItem(id: 'rose_garden', name: 'حديقة ورود', emoji: '🌷', description: 'حديقة كاملة… لأن حبكما ما يكفيه باقة', price: 400, category: GiftCategory.roses, rarity: GiftRarity.legendary, sortOrder: 3),

    // ===== شوكولاتة =====
    const GiftCatalogItem(id: 'choco_bar', name: 'لوح شوكولاتة', emoji: '🍫', description: 'حلا بسيط يسعد القلب', price: 60, category: GiftCategory.chocolate, rarity: GiftRarity.common, sortOrder: 10),
    const GiftCatalogItem(id: 'choco_box', name: 'علبة شوكولاتة فاخرة', emoji: '🎀', description: 'علبة مشكلة من أفخر الأنواع', price: 180, category: GiftCategory.chocolate, rarity: GiftRarity.rare, sortOrder: 11),

    // ===== قهوة =====
    const GiftCatalogItem(id: 'coffee_cup', name: 'فنجان قهوة', emoji: '☕', description: 'قهوتك الصباحية عليّ اليوم', price: 40, category: GiftCategory.coffee, rarity: GiftRarity.common, sortOrder: 20),
    const GiftCatalogItem(id: 'coffee_date', name: 'موعد قهوة', emoji: '🫖', description: 'دعوة لقهوة مع بعض (ولو عن بعد)', price: 120, category: GiftCategory.coffee, rarity: GiftRarity.rare, sortOrder: 21),

    // ===== رسائل =====
    const GiftCatalogItem(id: 'love_letter', name: 'رسالة حب', emoji: '💌', description: 'رسالة مختومة بقبلة', price: 80, category: GiftCategory.messages, rarity: GiftRarity.common, sortOrder: 30),
    const GiftCatalogItem(id: 'love_poem', name: 'قصيدة غزل', emoji: '📜', description: 'أبيات شعر باسم شريكك', price: 200, category: GiftCategory.messages, rarity: GiftRarity.rare, sortOrder: 31),

    // ===== مناسبات =====
    const GiftCatalogItem(id: 'occ_balloon', name: 'بالونات احتفال', emoji: '🎈', description: 'للاحتفال بأي إنجاز صغير', price: 70, category: GiftCategory.occasions, rarity: GiftRarity.common, sortOrder: 40),
    const GiftCatalogItem(id: 'occ_cake', name: 'كيكة مناسبات', emoji: '🎂', description: 'كل عام وأنتما بخير', price: 160, category: GiftCategory.occasions, rarity: GiftRarity.rare, sortOrder: 41),
    const GiftCatalogItem(id: 'occ_fireworks', name: 'ألعاب نارية', emoji: '🎆', description: 'سماء كاملة تحتفل بكما', price: 350, category: GiftCategory.occasions, rarity: GiftRarity.legendary, isNew: true, sortOrder: 42),

    // ===== مميزة =====
    // أمثلة على شروط الفتح والحدود اليومية
    const GiftCatalogItem(id: 'sp_star', name: 'نجمة باسمكما', emoji: '⭐', description: 'نجمة في سماء بيننا تحمل اسمكما', price: 500, category: GiftCategory.special, rarity: GiftRarity.legendary, sortOrder: 50, requiredLevel: 3, tags: ['premium'], animationType: 'sparkle'),
    const GiftCatalogItem(id: 'sp_crown', name: 'تاج الحب', emoji: '👑', description: 'لأن شريكك يستاهل التتويج', price: 600, category: GiftCategory.special, rarity: GiftRarity.legendary, isNew: true, sortOrder: 51, requiredStreak: 3, maxPurchasesPerDay: 1, tags: ['premium'], animationType: 'crown'),
  ];
}
