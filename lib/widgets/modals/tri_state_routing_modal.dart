import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';
import 'add_habit_modal.dart';
import 'add_task_modal.dart';
import 'add_goal_modal.dart';

class TriStateRoutingModal extends StatelessWidget {
  final VoidCallback onAdded;
  final VoidCallback onDismiss;

  const TriStateRoutingModal({
    super.key,
    required this.onAdded,
    required this.onDismiss,
  });

  void _routeTo(BuildContext context, Widget modal) {
    HapticWrapper.medium();
    Navigator.of(context).pop(); // Close routing modal
    showCupertinoModalPopup(
      context: context,
      builder: (context) => modal,
    ).then((_) =>
        onDismiss()); // Ensure main screen scales back when specific modal closes
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.systemGray6.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          top: 32,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.systemBlack,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildRouteButton(
              context: context,
              icon: CupertinoIcons.repeat,
              title: 'Habit',
              subtitle: 'Recurring daily action',
              onTap: () => _routeTo(context, AddHabitModal(onAdded: onAdded)),
            ),
            const SizedBox(height: 16),
            _buildRouteButton(
              context: context,
              icon: CupertinoIcons.checkmark_square,
              title: 'Task',
              subtitle: 'One-off daily action',
              onTap: () => _routeTo(context, AddTaskModal(onAdded: onAdded)),
            ),
            const SizedBox(height: 16),
            _buildRouteButton(
              context: context,
              icon: CupertinoIcons.flag,
              title: 'Goal',
              subtitle: 'Time-bound target (Week/Month/Year)',
              onTap: () => _routeTo(context, AddGoalModal(onAdded: onAdded)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.pureCeramicWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.systemBlack.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.focusBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.focusBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.systemBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.systemGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.systemGray),
          ],
        ),
      ),
    );
  }
}
