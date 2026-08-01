import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

/// تعديل البيانات الشخصية
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _picker = ImagePicker();
  XFile? _newPhoto;
  Uint8List? _newPhotoBytes;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: context.read<AuthViewModel>().currentUser?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600, // صورة شخصية لا تحتاج أكثر
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() { _newPhoto = picked; _newPhotoBytes = bytes; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authVm = context.read<AuthViewModel>();
    final vm = context.read<SettingsViewModel>();
    final user = authVm.currentUser!;

    var ok = true;
    if (_newPhoto != null) {
      ok = await vm.updatePhoto(uid: user.uid, image: _newPhoto!);
    }
    if (ok && _nameCtrl.text.trim() != user.name) {
      ok = await vm.updateName(
        uid: user.uid,
        name: _nameCtrl.text,
        coupleId: user.coupleId,
      );
    }

    if (ok) await authVm.loadCurrentUser();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حفظ التعديلات ✅' : (vm.errorMessage ?? 'حدث خطأ')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final vm = context.watch<SettingsViewModel>();
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              // الصورة
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      backgroundImage: _newPhoto != null
                          ? MemoryImage(_newPhotoBytes!)
                          : (user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null) as ImageProvider?,
                      child: _newPhoto == null && user.photoUrl == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0] : '؟',
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark),
                            )
                          : null,
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: InkWell(
                        onTap: vm.isBusy ? null : _pickPhoto,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: AppColors.romanticGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              AppTextField(
                controller: _nameCtrl,
                hint: 'الاسم',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.done,
                validator: Validators.name,
              ),
              const SizedBox(height: 14),

              // البريد (غير قابل للتعديل)
              TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, size: 22),
                  helperText: 'البريد الإلكتروني لا يمكن تغييره',
                ),
              ),
              const SizedBox(height: 14),

              // رمز الدعوة
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.qr_code_rounded,
                      color: AppColors.secondary),
                  title: const Text('رمز الدعوة الخاص بك',
                      style: TextStyle(fontSize: 13.5)),
                  subtitle: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      user.inviteCode,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: vm.isBusy ? null : _save,
                child: vm.isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
