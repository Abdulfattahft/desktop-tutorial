import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../games/data/models/game_models.dart';
import '../../../linking/data/models/couple_model.dart';

/// مستودع الرئيسية — تيارات لحظية لكل بيانات الشاشة
class HomeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// تيار بيانات مستخدم (أنا أو شريكي)
  Stream<UserModel?> userStream(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);

  /// تيار مستند الزوجين (النقاط، المستوى، الستريك، موعد الزواج)
  Stream<CoupleModel?> coupleStream(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .snapshots()
      .map((doc) => doc.exists ? CoupleModel.fromMap(doc.data()!) : null);

  /// آخر نشاط مشترك (أحدث لعبة ملعوبة)
  Stream<GameHistoryEntry?> lastActivityStream(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection(AppConstants.gameHistoryCollection)
      .orderBy('playedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : GameHistoryEntry.fromMap(snap.docs.first.data()));

  /// تحديد أو تعديل موعد الزواج
  Future<void> setWeddingDate(String coupleId, DateTime date) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .update({'weddingDate': Timestamp.fromDate(date)});

  /// تحديث آخر ظهور لي (يُستدعى عند فتح الرئيسية)
  Future<void> touchLastActive(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'lastActive': Timestamp.now()});
}
