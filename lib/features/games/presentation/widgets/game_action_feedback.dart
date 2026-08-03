import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/games_viewmodel.dart';

final GlobalKey<ScaffoldMessengerState> gameScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// يعرض حالة تنفيذ إجراءات الألعاب ورسائل الخطأ على مستوى التطبيق كله.
class GameActionFeedback extends StatefulWidget {
  const GameActionFeedback({required this.child, super.key});

  final Widget child;

  @override
  State<GameActionFeedback> createState() => _GameActionFeedbackState();
}

class _GameActionFeedbackState extends State<GameActionFeedback> {
  GamesViewModel? _viewModel;
  int _shownFeedbackRevision = 0;
  int _handledCompletionRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<GamesViewModel>();
    if (identical(next, _viewModel)) return;
    _viewModel?.removeListener(_handleViewModelChange);
    _viewModel = next..addListener(_handleViewModelChange);
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelChange);
    super.dispose();
  }

  void _handleViewModelChange() {
    final viewModel = _viewModel;
    if (!mounted || viewModel == null) return;

    if (viewModel.completionRevision > _handledCompletionRevision) {
      _handledCompletionRevision = viewModel.completionRevision;
      unawaited(context.read<AuthViewModel>().loadCurrentUser());
    }

    if (viewModel.feedbackRevision <= _shownFeedbackRevision) return;

    final message = viewModel.errorMessage;
    if (message == null || message.trim().isEmpty) return;
    _shownFeedbackRevision = viewModel.feedbackRevision;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = gameScaffoldMessengerKey.currentState;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'حسنًا',
              textColor: Colors.white,
              onPressed: messenger.hideCurrentSnackBar,
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<GamesViewModel, bool>((vm) => vm.isBusy);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (isBusy)
          const PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: IgnorePointer(
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ),
      ],
    );
  }
}
