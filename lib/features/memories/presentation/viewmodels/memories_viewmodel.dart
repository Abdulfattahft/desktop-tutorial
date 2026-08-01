import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/memory_model.dart';
import '../../data/repositories/memories_repository.dart';

class MemoriesViewModel extends ChangeNotifier {
  final MemoriesRepository _repo;
  MemoriesViewModel(this._repo);

  bool isUploading = false;
  double uploadProgress = 0;
  String? errorMessage;

  Stream<List<MemoryModel>> memoriesStream(String coupleId) =>
      _repo.memoriesStream(coupleId);

  Stream<MemoryModel?> memoryStream(String coupleId, String memoryId) =>
      _repo.memoryStream(coupleId, memoryId);

  Future<bool> addMemory({
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
  }) async {
    if (isUploading) return false;
    isUploading = true;
    uploadProgress = 0;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.addMemory(
        coupleId: coupleId,
        createdBy: createdBy,
        title: title,
        note: note,
        date: date,
        category: category,
        location: location,
        images: images,
        partnerUid: partnerUid,
        authorName: authorName,
        onProgress: (p) {
          uploadProgress = p;
          notifyListeners();
        },
      );
      return true;
    } catch (_) {
      errorMessage = 'تعذر حفظ الذكرى، تأكد من اتصالك وحاول مرة أخرى';
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike({
    required String coupleId,
    required MemoryModel memory,
    required String uid,
    String? partnerUid,
    String? likerName,
  }) =>
      _repo.toggleLike(
        coupleId: coupleId,
        memoryId: memory.id,
        uid: uid,
        like: !memory.likedBy(uid),
        partnerUid: partnerUid,
        likerName: likerName,
        memoryTitle: memory.title,
      );

  Future<bool> addComment({
    required String coupleId,
    required String memoryId,
    required MemoryComment comment,
    String? partnerUid,
    String? memoryTitle,
  }) async {
    try {
      await _repo.addComment(
          coupleId: coupleId,
          memoryId: memoryId,
          comment: comment,
          partnerUid: partnerUid,
          memoryTitle: memoryTitle);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMemory({
    required String coupleId,
    required MemoryModel memory,
  }) async {
    try {
      await _repo.deleteMemory(coupleId: coupleId, memory: memory);
      return true;
    } catch (_) {
      errorMessage = 'تعذر حذف الذكرى';
      notifyListeners();
      return false;
    }
  }
}
