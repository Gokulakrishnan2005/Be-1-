import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';
import 'squircle_card.dart';

class GoalCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onUpdated;

  const GoalCard({super.key, required this.goal, required this.onUpdated});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late double _currentValue;
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.goal.currentValue;

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _buttonScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.9)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_buttonController);
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  void _incrementGoal() async {
    if (_currentValue >= widget.goal.targetValue) return;

    HapticWrapper.medium();
    _buttonController.forward(from: 0.0);

    setState(() {
      _currentValue += 1;
      if (_currentValue > widget.goal.targetValue) {
        _currentValue = widget.goal.targetValue;
      }
    });

    final storage = context.read<StorageService>();
    final updatedGoal = widget.goal.copyWith(
      newCurrentValue: _currentValue,
    );

    await storage.saveGoal(updatedGoal);
    widget.onUpdated();
  }

  void _showEditDialog() async {
    final titleCtrl = TextEditingController(text: widget.goal.title);
    final targetCtrl =
        TextEditingController(text: widget.goal.targetValue.toStringAsFixed(0));
    final unitCtrl = TextEditingController(text: widget.goal.unit);

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Edit Goal'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: titleCtrl,
                placeholder: 'Goal title',
                style: const TextStyle(color: AppTheme.systemBlack),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: targetCtrl,
                placeholder: 'Target value',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.systemBlack),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: unitCtrl,
                placeholder: 'Unit (e.g. pages, km)',
                style: const TextStyle(color: AppTheme.systemBlack),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (result == true) {
      final newTitle = titleCtrl.text.trim();
      final newTarget = double.tryParse(targetCtrl.text.trim());
      final newUnit = unitCtrl.text.trim();

      if (newTitle.isNotEmpty && newTarget != null && newTarget > 0) {
        final storage = context.read<StorageService>();
        final updatedGoal = widget.goal.copyWith(
          newTitle: newTitle,
          newTargetValue: newTarget,
          newUnit: newUnit.isNotEmpty ? newUnit : null,
        );
        await storage.saveGoal(updatedGoal);
        widget.onUpdated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        (_currentValue / widget.goal.targetValue).clamp(0.0, 1.0);
    final bool isCompleted = _currentValue >= widget.goal.targetValue;

    return Dismissible(
        key: ValueKey(widget.goal.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          HapticWrapper.heavy();
          final confirm = await showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Delete Goal?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue)),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          );
          if (confirm != true) return false;

          final storage = context.read<StorageService>();
          var goals = storage.getGoals();
          goals.removeWhere((g) => g.id == widget.goal.id);
          await storage.saveAllGoals(goals);
          return true;
        },
        onDismissed: (direction) {
          widget.onUpdated();
        },
        background: Container(
          color: CupertinoColors.systemRed,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24.0),
          child: const Icon(CupertinoIcons.trash_fill,
              color: AppTheme.pureCeramicWhite, size: 28),
        ),
        child: GestureDetector(
            onLongPress: _showEditDialog,
            child: SquircleCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.goal.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.systemBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_currentValue.toStringAsFixed(0)} / ${widget.goal.targetValue.toStringAsFixed(0)} ${widget.goal.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.systemGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 12,
                              child: Stack(
                                children: [
                                  Container(color: AppTheme.systemGray6),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppTheme.growthGreen
                                            : AppTheme.focusBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _incrementGoal,
                          behavior: HitTestBehavior.opaque,
                          child: ScaleTransition(
                            scale: _buttonScaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppTheme.systemGray6
                                    : AppTheme.systemBlack,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '+ 1',
                                style: TextStyle(
                                  color: isCompleted
                                      ? AppTheme.systemGray
                                      : AppTheme.pureCeramicWhite,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )));
  }
}
