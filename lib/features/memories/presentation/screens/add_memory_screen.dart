import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/memory_model.dart';
import '../viewmodels/memories_viewmodel.dart';

/// شاشة إضافة ذكرى جديدة
class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _picker = ImagePicker();

  final List<XFile> _images = [];
  DateTime _date = DateTime.now();
  MemoryCategory _category = MemoryCategory.date;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  /// اختيار الصور — الضغط يتم هنا: جودة 70% وعرض أقصى 1280px
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(6 - _images.length));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'تاريخ الذكرى',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف صورة واحدة على الأقل 📷'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final user = context.read<AuthViewModel>().currentUser!;
    final vm = context.read<MemoriesViewModel>();
    final ok = await vm.addMemory(
      coupleId: user.coupleId!,
      createdBy: user.uid,
      title: _titleCtrl.text,
      note: _noteCtrl.text,
      date: _date,
      category: _category,
      location: _locationCtrl.text,
      images: _images,
      partnerUid: user.partnerId,
      authorName: user.name,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حُفظت الذكرى 💕'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'حدث خطأ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemoriesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('ذكرى جديدة ✨')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              // ===== الصور =====
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // زر الإضافة
                    if (_images.length < 6)
                      InkWell(
                        onTap: vm.isUploading ? null : _pickImages,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.primary.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: AppColors.primary, size: 30),
                              SizedBox(height: 4),
                              Text('إضافة صور',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.primaryDark)),
                            ],
                          ),
                        ),
                      ),
                    ..._images.asMap().entries.map(
                          (e) => Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: FutureBuilder<Uint8List>(
                                    future: e.value.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox(
                                          width: 100, height: 100,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        );
                                      }
                                      return Image.memory(snapshot.data!,
                                          width: 100, height: 100, fit: BoxFit.cover);
                                    },
                                  ),
                                ),
                                PositionedDirectional(
                                  top: 4,
                                  end: 4,
                                  child: InkWell(
                                    onTap: () => setState(
                                        () => _images.removeAt(e.key)),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: _titleCtrl,
                hint: 'عنوان الذكرى',
                icon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب عنوانًا' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                    hintText: 'احكِ عن هذه اللحظة… 💭'),
              ),
              const SizedBox(height: 6),

              // التاريخ + الموقع
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded,
                          size: 18),
                      label: Text(
                          intl.DateFormat('d MMM yyyy', 'ar')
                              .format(_date),
                          style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _locationCtrl,
                hint: 'الموقع (اختياري)',
                icon: Icons.place_rounded,
              ),

              const SizedBox(height: 18),

              // ===== التصنيف =====
              Text('التصنيف',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MemoryCategory.values.map((c) {
                  final selected = c == _category;
                  return ChoiceChip(
                    label: Text('${c.emoji} ${c.label}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: c.color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected
                          ? c.color
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: selected
                              ? c.color
                              : AppColors.textSecondary
                                  .withOpacity(0.3)),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ===== زر الحفظ / التقدم =====
              if (vm.isUploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: vm.uploadProgress,
                    minHeight: 10,
                    backgroundColor: AppColors.surface,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'جارٍ رفع الصور… ${(vm.uploadProgress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                  label: const Text('حفظ الذكرى'),
                ).animate().fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
