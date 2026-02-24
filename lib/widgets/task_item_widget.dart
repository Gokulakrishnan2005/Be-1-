import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';

import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';

class TaskItemWidget extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onDismissed;

  const TaskItemWidget(
      {super.key,
      required this.task,
      required this.onToggle,
      this.onDismissed});

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget>
    with SingleTickerProviderStateMixin {
  late bool _isChecked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.task.isCompleted;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.85)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 0.85, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() async {
    if (_isChecked) return; // Prevent unchecking for simplicity

    HapticWrapper.light();
    _controller.forward(from: 0.0);

    setState(() {
      _isChecked = true;
    });

    final storage = context.read<StorageService>();
    final updatedTask = TaskItem(
      id: widget.task.id,
      title: widget.task.title,
      isCompleted: true,
      isArchived: widget.task.isArchived,
      snoozeCount: widget.task.snoozeCount,
      createdAt: widget.task.createdAt,
      completedAt: DateTime.now(),
    );

    await storage.saveTask(updatedTask);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final bool isStrike3 = widget.task.snoozeCount >= 2;
    final Color dismissBgColor =
        isStrike3 ? CupertinoColors.systemRed : const Color(0xFFFF9500);
    final IconData dismissIcon =
        isStrike3 ? CupertinoIcons.trash_fill : CupertinoIcons.calendar;

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          HapticWrapper.heavy();
          final storage = context.read<StorageService>();
          var tasks = storage.getTasks();
          tasks.removeWhere((t) => t.id == widget.task.id);
          await storage.saveAllTasks(tasks);
          return true;
        }

        // Snooze Logic (startToEnd)
        if (isStrike3) {
          HapticWrapper.heavy();
        } else {
          HapticWrapper.medium();
        }

        final storage = context.read<StorageService>();

        if (isStrike3) {
          var tasks = storage.getTasks();
          tasks.removeWhere((t) => t.id == widget.task.id);
          await storage.saveAllTasks(tasks);
        } else {
          final now = DateTime.now();
          final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

          final updatedTask = TaskItem(
            id: widget.task.id,
            title: widget.task.title,
            isCompleted: false,
            isArchived: widget.task.isArchived,
            snoozeCount: widget.task.snoozeCount + 1,
            createdAt: tomorrowMidnight,
            completedAt: widget.task.completedAt,
          );

          await storage.saveTask(updatedTask);
        }

        return true;
      },
      onDismissed: (direction) {
        if (widget.onDismissed != null) {
          widget.onDismissed!();
        } else {
          widget.onToggle();
        }
      },
      background: Container(
        color: dismissBgColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24.0),
        child: Icon(dismissIcon, color: AppTheme.pureCeramicWhite, size: 28),
      ),
      secondaryBackground: Container(
        color: CupertinoColors.systemRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        child: const Icon(CupertinoIcons.trash_fill,
            color: AppTheme.pureCeramicWhite, size: 28),
      ),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isChecked ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppTheme.systemGray.withOpacity(0.2), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isChecked
                            ? AppTheme.systemBlack
                            : AppTheme.systemGray,
                        width: 2,
                      ),
                      color: _isChecked
                          ? AppTheme.systemBlack
                          : Colors.transparent,
                    ),
                    child: _isChecked
                        ? const Icon(CupertinoIcons.checkmark_alt,
                            size: 20, color: AppTheme.pureCeramicWhite)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.systemBlack,
                      fontWeight: FontWeight.w500,
                      decoration: _isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
