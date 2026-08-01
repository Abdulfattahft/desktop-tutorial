import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/settings_models.dart';

/// مستودع الإعدادات — الحساب، العلاقة، المظهر، البيانات
class SettingsRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _themeKey = 'theme_pref';

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(AppConstants.usersCollection).doc(uid);

  DocumentReference<Map<String, dynamic>> _coupleRef(String coupleId) =>
      _db.collection(AppConstants.couplesCollection).doc(coupleId);

  // ===================== الحساب =====================

  /// تحديث الاسم (وتحديثه في مستند الزوجين أيضًا ليبقى متسقًا)
  Future<void> updateName({
    required String uid,
    required String name,
    String? coupleId,
  }) async {
    final clean = name.trim();
    if (clean.length < 2) {
      throw const SettingsException('الاسم قصير جدًا');
    }
    await _userRef(uid).update({'name': clean});
    await _auth.currentUser?.updateDisplayName(clean);
    if (coupleId != null) {
      await _coupleRef(coupleId).update({'names.$uid': clean});
    }
  }

  /// رفع صورة الملف الشخصي
  Future<String> updatePhoto({
    required String uid,
    required XFile image,
  }) async {
    final ref = _storage.ref('profiles/$uid/avatar.jpg');
    final bytes = await image.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _userRef(uid).update({'photoUrl': url});
    return url;
  }

  /// حذف الحساب نهائيًا
  ///
  /// Firebase يرفض الحذف لجلسة قديمة، لذا نعيد المصادقة أولًا
  /// البيانات المشتركة تبقى للطرف الآخر (حسب تصميم المنتج)
  Future<void> deleteAccount({
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const SettingsException('لا توجد جلسة نشطة');
    }

    // 1) إعادة المصادقة
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
            email: user.email!, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw SettingsException(
        e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'كلمة المرور غير صحيحة'
            : 'تعذر التحقق، حاول مرة أخرى',
      );
    }

    final uid = user.uid;

    // 2) فك الارتباط عن الشريك حتى لا يبقى مرتبطًا بحساب محذوف
    final myDoc = await _userRef(uid).get();
    final partnerId = myDoc.data()?['partnerId'] as String?;
    if (partnerId != null) {
      try {
        await _userRef(partnerId)
            .update({'partnerId': null, 'coupleId': null});
      } catch (_) {}
    }

    // 3) حذف صورة الملف الشخصي (أفضل جهد)
    try {
      await _storage.ref('profiles/$uid/avatar.jpg').delete();
    } catch (_) {}

    // 4) حذف مستند المستخدم ثم حساب المصادقة
    try {
      await _userRef(uid).delete();
    } catch (_) {}

    try {
      await user.delete();
    } on FirebaseAuthException {
      throw const SettingsException(
          'تعذر حذف الحساب، سجّل خروجك وادخل مرة أخرى ثم أعد المحاولة');
    }
  }

  // ===================== العلاقة =====================

  /// طلب فصل العلاقة — يحتاج موافقة الطرف الآخر
  Future<void> requestUnlink({
    required String coupleId,
    required String uid,
  }) async {
    await _coupleRef(coupleId).update({
      'unlinkRequest': UnlinkRequest(
        requestedBy: uid,
        requestedAt: DateTime.now(),
      ).toMap(),
    });
  }

  /// إلغاء الطلب (من صاحبه) أو رفضه (من الطرف الآخر)
  Future<void> cancelUnlink(String coupleId) =>
      _coupleRef(coupleId).update({'unlinkRequest': FieldValue.delete()});

  /// تأكيد الفصل — يتم في Transaction واحدة للطرفين
  ///
  /// البيانات المشتركة (الذكريات، الهدايا، النقاط) تبقى محفوظة في
  /// مستند الزوجين، فيمكن استرجاعها لو أُعيد الربط لاحقًا
  Future<void> confirmUnlink({
    required String coupleId,
    required String uid,
  }) async {
    await _db.runTransaction((tx) async {
      final coupleDoc = await tx.get(_coupleRef(coupleId));
      if (!coupleDoc.exists) {
        throw const SettingsException('العلاقة غير موجودة');
      }
      final data = coupleDoc.data()!;
      final request =
          UnlinkRequest.fromMap(Map<String, dynamic>.from(
              data['unlinkRequest'] as Map? ?? const {}));

      // الحارس: لا بد من طلب معلّق، ومن الطرف الآخر
      if (request.status != UnlinkStatus.pending) {
        throw const SettingsException('لا يوجد طلب فصل معلّق');
      }
      if (request.requestedBy == uid) {
        throw const SettingsException(
            'بانتظار موافقة شريكك على الفصل');
      }

      final userIds = List<String>.from(data['userIds'] as List? ?? const []);

      // أرشفة العلاقة بدل حذفها — البيانات تبقى قابلة للاسترجاع
      tx.update(_coupleRef(coupleId), {
        'active': false,
        'unlinkedAt': Timestamp.now(),
        'unlinkRequest': FieldValue.delete(),
        'previousUserIds': userIds,
      });

      for (final id in userIds) {
        tx.update(_userRef(id), {
          'partnerId': null,
          'coupleId': null,
          // نحتفظ بالمعرّف حتى يمكن استرجاع العلاقة عند إعادة الربط
          'previousCoupleId': coupleId,
        });
      }
    });
  }

  // ===================== المظهر =====================

  Future<ThemePref> getThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemePrefX.fromName(prefs.getString(_themeKey));
  }

  Future<void> setThemePref(ThemePref pref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, pref.name);
  }

  // ===================== البيانات =====================

  /// مسح ذاكرة الصور المؤقتة
  Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
  }

  /// إعادة تحميل بيانات Firestore من الخادم
  Future<void> refreshData() async {
    // إفراغ الذاكرة المحلية يجبر التيارات على القراءة من الخادم
    await _db.clearPersistence().catchError((_) {});
  }
}
