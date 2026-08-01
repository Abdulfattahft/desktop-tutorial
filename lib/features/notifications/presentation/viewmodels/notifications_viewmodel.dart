import 'package:flutter/foundation.dart';

import '../../data/models/notification_models.dart';
import '../../data/repositories/notifications_repository.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationsRepository _repo;
  NotificationsViewModel(this._repo);

  Stream<List<AppNotification>> notificationsStream(String uid) =>
      _repo.notificationsStream(uid);

  Stream<int> unreadCountStream(String uid) => _repo.unreadCountStream(uid);

  Stream<NotificationPrefs> prefsStream(String uid) =>
      _repo.prefsStream(uid);

  Future<void> markAsRead(String uid, String id) =>
      _repo.markAsRead(uid, id);

  Future<void> markAllAsRead(String uid) => _repo.markAllAsRead(uid);

  Future<void> delete(String uid, String id) => _repo.delete(uid, id);

  Future<void> deleteAll(String uid) => _repo.deleteAll(uid);

  Future<void> setPref({
    required String uid,
    required NotificationCategory category,
    required bool enabled,
  }) =>
      _repo.setPref(uid: uid, category: category, enabled: enabled);

  Future<void> saveFcmToken(String uid, String token) =>
      _repo.saveFcmToken(uid, token);
}
