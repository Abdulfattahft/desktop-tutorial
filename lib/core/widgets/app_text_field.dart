import 'package:flutter/material.dart';

/// حقل نصي موحد يُستخدم في كل نماذج التطبيق
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// دوال تحقق جاهزة
class Validators {
  Validators._();

  static String? name(String? v) {
    if (v == null || v.trim().length < 2) return 'اكتب اسمك';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'اكتب بريدك الإلكتروني';
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!regex.hasMatch(v.trim())) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
    return null;
  }
}
