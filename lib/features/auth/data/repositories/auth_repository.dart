import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../models/user_model.dart';

/// استثناء مصادقة برسالة عربية جاهزة للعرض.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

/// مستودع المصادقة — كل التعامل مع FirebaseAuth وFirestore هنا.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// إنشاء حساب جديد + مستند المستخدم في Firestore مع رمز دعوة فريد.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    User? createdAuthUser;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdAuthUser = cred.user;
      final uid = createdAuthUser!.uid;

      await createdAuthUser.updateDisplayName(name.trim());

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
      await _deleteIncompleteUser(createdAuthUser);
      throw AuthException(_mapAuthError(e.code, e.message));
    } on FirebaseException catch (e) {
      await _deleteIncompleteUser(createdAuthUser);
      throw AuthException(_mapFirebaseServiceError(e.code, e.message));
    } catch (e) {
      await _deleteIncompleteUser(createdAuthUser);
      throw AuthException('تعذر إنشاء الحساب: ${e.runtimeType}');
    }
  }

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
      throw AuthException(_mapAuthError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseServiceError(e.code, e.message));
    } catch (e) {
      throw AuthException('تعذر تسجيل الدخول: ${e.runtimeType}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code, e.message));
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseServiceError(e.code, e.message));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserModel> getUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      throw const AuthException('لم يتم العثور على بيانات الحساب');
    }
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> userStream(String uid) => _users.doc(uid).snapshots().map(
        (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null,
      );

  Future<void> updateLastActive(String uid) =>
      _users.doc(uid).update({'lastActive': Timestamp.now()});

  Future<String> _generateUniqueInviteCode() async {
    for (var i = 0; i < 5; i++) {
      final code = AppUtils.generateInviteCode(AppConstants.inviteCodeLength);
      final existing =
          await _users.where('inviteCode', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    return AppUtils.generateInviteCode(AppConstants.inviteCodeLength + 2);
  }

  Future<void> _deleteIncompleteUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      // لا نخفي الخطأ الأساسي إذا تعذر تنظيف الحساب غير المكتمل.
    }
  }

  String _mapAuthError(String code, String? message) {
    final normalizedMessage = (message ?? '').toUpperCase();

    // بعض أخطاء Firebase Web تصل بكود unknown مع السبب داخل الرسالة.
    if (normalizedMessage.contains('CONFIGURATION_NOT_FOUND')) {
      return 'إعداد Authentication غير مكتمل في Firebase. فعّل Email/Password ثم اضغط Save.';
    }
    if (normalizedMessage.contains('OPERATION_NOT_ALLOWED')) {
      return 'تسجيل البريد وكلمة المرور غير مفعّل في Firebase Authentication.';
    }
    if (normalizedMessage.contains('API_KEY_INVALID')) {
      return 'مفتاح Firebase API غير صحيح. راجع إعداد تطبيق الويب.';
    }
    if (normalizedMessage.contains('PROJECT_NOT_FOUND')) {
      return 'تعذر العثور على مشروع Firebase المرتبط بالموقع.';
    }

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
        return 'هذا البريد مسجل مسبقًا. جرّب تسجيل الدخول بدل إنشاء حساب جديد.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول بعد قليل';
      case 'network-request-failed':
        return 'تعذر الاتصال بخوادم Firebase. تحقق من الإنترنت أو مانع الإعلانات.';
      case 'operation-not-allowed':
        return 'فعّل Email/Password من Firebase Authentication ثم اضغط Save.';
      case 'unauthorized-domain':
        return 'أضف abdulfattahft.github.io إلى Authorized domains في Firebase Authentication.';
      case 'configuration-not-found':
        return 'إعداد Authentication غير مكتمل في Firebase.';
      case 'app-not-authorized':
        return 'تطبيق الويب غير مصرح له باستخدام Firebase Authentication.';
      case 'invalid-api-key':
        return 'مفتاح Firebase API غير صحيح.';
      default:
        return 'خطأ Firebase أثناء المصادقة: $code';
    }
  }

  String _mapFirebaseServiceError(String code, String? message) {
    switch (code) {
      case 'permission-denied':
        return 'قواعد Firestore تمنع حفظ الحساب. تأكد من نشر Rules.';
      case 'unavailable':
        return 'خدمة Firebase غير متاحة مؤقتًا، حاول بعد قليل.';
      case 'failed-precondition':
        return 'إعداد Firestore غير مكتمل: ${message ?? code}';
      default:
        return 'خطأ Firebase في حفظ البيانات: $code';
    }
  }
}
