import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// تصنيفات الذكريات — أضف تصنيفًا هنا ويظهر تلقائيًا في كل الواجهات
enum MemoryCategory { date, travel, occasion, message, other }

extension MemoryCategoryX on MemoryCategory {
  String get label => switch (this) {
        MemoryCategory.date => 'موعد',
        MemoryCategory.travel => 'سفر',
        MemoryCategory.occasion => 'مناسبة',
        MemoryCategory.message => 'رسالة',
        MemoryCategory.other => 'أخرى',
      };

  String get emoji => switch (this) {
        MemoryCategory.date => '💑',
        MemoryCategory.travel => '✈️',
        MemoryCategory.occasion => '🎉',
        MemoryCategory.message => '💌',
        MemoryCategory.other => '✨',
      };

  Color get color => switch (this) {
        MemoryCategory.date => AppColors.primary,
        MemoryCategory.travel => const Color(0xFF5EA3A3),
        MemoryCategory.occasion => AppColors.secondary,
        MemoryCategory.message => const Color(0xFF9C7BB8),
        MemoryCategory.other => const Color(0xFFE08E45),
      };
}

/// تعليق بسيط مضمّن داخل الذكرى
class MemoryComment {
  final String uid;
  final String name;
  final String text;
  final DateTime at;

  const MemoryComment({
    required this.uid,
    required this.name,
    required this.text,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'text': text,
        'at': Timestamp.fromDate(at),
      };

  factory MemoryComment.fromMap(Map<String, dynamic> map) => MemoryComment(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        text: map['text'] as String? ?? '',
        at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// ذكرى مخزنة في couples/{coupleId}/memories/{id}
class MemoryModel {
  final String id;
  final String createdBy;
  final String title;
  final String note;
  final DateTime date; // تاريخ الذكرى نفسها (ليس تاريخ الإضافة)
  final String? location;
  final MemoryCategory category;
  final List<String> imageUrls;
  final Map<String, bool> likes; // uid → أعجب
  final List<MemoryComment> comments;
  final DateTime createdAt;

  const MemoryModel({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.note,
    required this.date,
    this.location,
    required this.category,
    required this.imageUrls,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  int get likesCount => likes.values.where((v) => v).length;
  bool likedBy(String uid) => likes[uid] == true;

  /// هل هذه الذكرى "في مثل هذا اليوم" من سنة سابقة؟
  bool get isOnThisDay {
    final now = DateTime.now();
    return date.month == now.month &&
        date.day == now.day &&
        date.year < now.year;
  }

  int get yearsAgo => DateTime.now().year - date.year;

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdBy': createdBy,
        'title': title,
        'note': note,
        'date': Timestamp.fromDate(date),
        'location': location,
        'category': category.name,
        'imageUrls': imageUrls,
        'likes': likes,
        'comments': comments.map((c) => c.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MemoryModel.fromMap(Map<String, dynamic> map) => MemoryModel(
        id: map['id'] as String,
        createdBy: map['createdBy'] as String? ?? '',
        title: map['title'] as String? ?? '',
        note: map['note'] as String? ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        location: map['location'] as String?,
        category: MemoryCategory.values
            .byName(map['category'] as String? ?? 'other'),
        imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
        likes: Map<String, bool>.from(map['likes'] as Map? ?? const {}),
        comments: (map['comments'] as List? ?? const [])
            .map((c) =>
                MemoryComment.fromMap(Map<String, dynamic>.from(c)))
            .toList(),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
