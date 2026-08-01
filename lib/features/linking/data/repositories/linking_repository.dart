import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/couple_model.dart';

/// استثناء ربط برسالة عربية جاهزة للعرض
class LinkException implements Exception {
  final String message;
  const LinkException(this.message);
}

/// مستودع ربط الشريكين
class LinkingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);
  CollectionReference<Map<String, dynamic>> get _couples =>
      _db.collection(AppConstants.couplesCollection);

  /// الربط برمز الدعوة — العملية كلها داخل Transaction لضمان عدم التضارب
  ///
  /// التحققات:
  /// 1. الرمز موجود فعلًا
  /// 2. ليس رمز المستخدم نفسه
  /// 3. صاحب الرمز غير مرتبط مسبقًا
  /// 4. المستخدم الحالي غير مرتبط مسبقًا
  Future<CoupleModel> linkWithCode({
    required String myUid,
    required String code,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw const LinkException('اكتب رمز الدعوة أولًا');
    }

    // الاستعلام عن صاحب الرمز (الاستعلامات لا تعمل داخل Transaction)
    final query = await _users
        .where('inviteCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw const LinkException('الرمز غير صحيح، تأكد منه وحاول مرة أخرى');
    }

    final partnerUid = query.docs.first.id;

    if (partnerUid == myUid) {
      throw const LinkException('هذا رمزك أنت 😅 اطلب رمز شريكك');
    }

    // المعاملة الذرية: قراءة الطرفين، التحقق، ثم الإنشاء والتحديث دفعة واحدة
    return _db.runTransaction<CoupleModel>((tx) async {
      final myDoc = await tx.get(_users.doc(myUid));
      final partnerDoc = await tx.get(_users.doc(partnerUid));

      if (!myDoc.exists || !partnerDoc.exists) {
        throw const LinkException('حدث خطأ في جلب البيانات، حاول مرة أخرى');
      }

      final me = UserModel.fromMap(myDoc.data()!);
      final partner = UserModel.fromMap(partnerDoc.data()!);

      if (me.isLinked) {
        throw const LinkException('حسابك مرتبط بشريك بالفعل');
      }
      if (partner.isLinked) {
        throw const LinkException('هذا الرمز مستخدم، صاحبه مرتبط بشريك آخر');
      }

      // إنشاء مستند الزوجين
      final coupleRef = _couples.doc();
      final couple = CoupleModel(
        id: coupleRef.id,
        userIds: [myUid, partnerUid],
        names: {myUid: me.name, partnerUid: partner.name},
        createdAt: DateTime.now(),
      );

      tx.set(coupleRef, couple.toMap());
      tx.update(_users.doc(myUid), {
        'partnerId': partnerUid,
        'coupleId': coupleRef.id,
      });
      tx.update(_users.doc(partnerUid), {
        'partnerId': myUid,
        'coupleId': coupleRef.id,
      });

      return couple;
    });
  }

  /// تيار بيانات المستخدم — نستخدمه لاكتشاف أن الشريك ربطنا من طرفه
  Stream<UserModel?> userStream(String uid) =>
      _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);

  /// جلب مستند الزوجين
  Future<CoupleModel?> getCouple(String coupleId) async {
    final doc = await _couples.doc(coupleId).get();
    return doc.exists ? CoupleModel.fromMap(doc.data()!) : null;
  }
}
