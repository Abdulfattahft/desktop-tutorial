import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../models/user_model.dart';

/// استثناء مصادقة برسالة عربية جاهزة للعرض
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

/// مستودع المصادقة — كل التعامل مع FirebaseAuth و Firestore هنا
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  /// تيار حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// إنشاء حساب جديد + مستند المستخدم في Firestore مع رمز دعوة فريد
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(name.trim());

      final inviteCode = await _generateUniqueInviteCode();
      final now = DateTime.now();

      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        inviteCode: inviteCode,
        createdAt: now,
        lastActive: now,
      );

      await _users.doc(uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  /// تسجيل الدخول
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await getUserData(cred.user!.uid);
      await updateLastActive(cred.user!.uid);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  /// إرسال رابط استعادة كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// جلب بيانات المستخدم من Firestore
  Future<UserModel> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      throw const AuthException('لم يتم العثور على بيانات الحساب');
    }
    return UserModel.fromMap(doc.data()!);
  }

  /// تيار بيانات المستخدم (لتحديث الواجهة لحظيًا)
  Stream<UserModel?> userStream(String uid) => _users.doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);

  Future<void> updateLastActive(String uid) =>
      _users.doc(uid).update({'lastActive': Timestamp.now()});

  /// توليد رمز دعوة غير مستخدم من قبل
  Future<String> _generateUniqueInviteCode() async {
    for (var i = 0; i < 5; i++) {
      final code = AppUtils.generateInviteCode(AppConstants.inviteCodeLength);
      final existing =
          await _users.where('inviteCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    // احتمال التكرار شبه معدوم، لكن كخطة أخيرة نطوّل الرمز
    return AppUtils.generateInviteCode(AppConstants.inviteCodeLength + 2);
  }

  /// ترجمة أكواد أخطاء Firebase إلى رسائل عربية واضحة
  String _mapError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب موقوف';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مسجل مسبقًا';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول بعد قليل';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت';
      default:
        return 'حدث خطأ غير متوقع، حاول مرة أخرى';
    }
  }
}
