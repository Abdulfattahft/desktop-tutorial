import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../notifications/data/repositories/notification_events.dart';
import '../../../notifications/data/repositories/notifications_repository.dart';
import '../models/memory_model.dart';

class MemoryException implements Exception {
  final String message;
  const MemoryException(this.message);
}

/// مستودع الذكريات — Firestore للبيانات و Storage للصور
class MemoriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationEvents _notify =
      NotificationEvents(NotificationsRepository());

  CollectionReference<Map<String, dynamic>> _memoriesRef(String coupleId) =>
      _db
          .collection(AppConstants.couplesCollection)
          .doc(coupleId)
          .collection(AppConstants.memoriesCollection);

  /// إضافة ذكرى: رفع الصور (المضغوطة مسبقًا من image_picker) ثم المستند
  Future<void> addMemory({
    required String coupleId,
    required String createdBy,
    required String title,
    required String note,
    required DateTime date,
    required MemoryCategory category,
    String? location,
    required List<XFile> images,
    String? partnerUid,
    String? authorName,
    void Function(double progress)? onProgress,
  }) async {
    final docRef = _memoriesRef(coupleId).doc();

    // رفع الصور واحدة واحدة مع تقدم إجمالي
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final ref = _storage
          .ref('memories/$coupleId/${docRef.id}/img_$i.jpg');
      final bytes = await images[i].readAsBytes();
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: images[i].mimeType ?? 'image/jpeg'),
      );
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0 && onProgress != null) {
          final filePart = snap.bytesTransferred / snap.totalBytes;
          onProgress((i + filePart) / images.length);
        }
      });
      await task;
      urls.add(await ref.getDownloadURL());
    }

    final memory = MemoryModel(
      id: docRef.id,
      createdBy: createdBy,
      title: title.trim(),
      note: note.trim(),
      date: date,
      location: location?.trim().isEmpty == true ? null : location?.trim(),
      category: category,
      imageUrls: urls,
      likes: const {},
      comments: const [],
      createdAt: DateTime.now(),
    );
    await docRef.set(memory.toMap());

    if (partnerUid != null) {
      try {
        await _notify.memoryAdded(
          toUid: partnerUid,
          fromUid: createdBy,
          authorName: authorName ?? 'شريكك',
          memoryTitle: memory.title,
          memoryId: docRef.id,
        );
      } catch (_) {}
    }
  }

  /// تيار الذكريات بترتيب زمني تنازلي (الأحدث أولًا)
  Stream<List<MemoryModel>> memoriesStream(String coupleId) =>
      _memoriesRef(coupleId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => MemoryModel.fromMap(d.data())).toList());

  /// تيار ذكرى واحدة — أخف بكثير من الاستماع للقائمة كاملة
  Stream<MemoryModel?> memoryStream(String coupleId, String memoryId) =>
      _memoriesRef(coupleId)
          .doc(memoryId)
          .snapshots()
          .map((d) => d.exists ? MemoryModel.fromMap(d.data()!) : null);

  /// إعجاب/إلغاء إعجاب
  Future<void> toggleLike({
    required String coupleId,
    required String memoryId,
    required String uid,
    required bool like,
    String? partnerUid,
    String? likerName,
    String? memoryTitle,
  }) async {
    await _memoriesRef(coupleId).doc(memoryId).update({'likes.$uid': like});
    // إشعار عند الإعجاب فقط (لا عند الإلغاء)
    if (like && partnerUid != null) {
      try {
        await _notify.likeAdded(
          toUid: partnerUid,
          fromUid: uid,
          likerName: likerName ?? 'شريكك',
          memoryTitle: memoryTitle ?? 'ذكراكما',
          memoryId: memoryId,
        );
      } catch (_) {}
    }
  }

  /// إضافة تعليق (مضمّن داخل المستند — كافٍ لطرفين)
  Future<void> addComment({
    required String coupleId,
    required String memoryId,
    required MemoryComment comment,
    String? partnerUid,
    String? memoryTitle,
  }) async {
    await _memoriesRef(coupleId).doc(memoryId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
    if (partnerUid != null) {
      try {
        await _notify.commentAdded(
          toUid: partnerUid,
          fromUid: comment.uid,
          authorName: comment.name,
          memoryTitle: memoryTitle ?? 'ذكراكما',
          memoryId: memoryId,
          commentAt: comment.at.millisecondsSinceEpoch.toString(),
        );
      } catch (_) {}
    }
  }

  /// حذف الذكرى — القواعد تسمح لصاحبها فقط
  /// نحذف المستند أولًا ثم الصور (أفضل جهد — الفشل غير حرج)
  Future<void> deleteMemory({
    required String coupleId,
    required MemoryModel memory,
  }) async {
    await _memoriesRef(coupleId).doc(memory.id).delete();
    for (var i = 0; i < memory.imageUrls.length; i++) {
      try {
        await _storage
            .ref('memories/$coupleId/${memory.id}/img_$i.jpg')
            .delete();
      } catch (_) {/* الصورة قد تكون محذوفة */}
    }
  }
}
