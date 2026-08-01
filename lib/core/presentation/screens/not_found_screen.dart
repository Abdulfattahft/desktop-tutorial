import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routing/app_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border_rounded, size: 72),
                const SizedBox(height: 20),
                Text('404', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  message ?? 'هذه الصفحة ليست بيننا بعد.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
