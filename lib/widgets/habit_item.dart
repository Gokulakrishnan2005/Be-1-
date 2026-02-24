import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';

class HabitItem extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback? onDismissed;

  const HabitItem(
      {super.key,
      required this.habit,
      required this.onToggle,
      this.onDismissed});

  @override
  State<HabitItem> createState() => _HabitItemState();
}

class _HabitItemState extends State<HabitItem>
    with SingleTickerProviderStateMixin {
  late bool _isChecked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.habit.isCompleted;

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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _toggle() async {
    if (_isChecked)
      return; // Prevent unchecking for simplicity/stoic philosophy

    final newStreak = widget.habit.streak + 1; // Assuming checking it adds 1
    if (newStreak >= 7) {
      HapticWrapper.heavy();
    } else {
      HapticWrapper.light();
    }

    _controller.forward(from: 0.0);

    setState(() {
      _isChecked = true;
    });

    final storage = context.read<StorageService>();
    final now = DateTime.now();
    bool wasCheckedToday = false;
    if (widget.habit.isCompleted) {
      wasCheckedToday = _isSameDay(widget.habit.createdAt,
          now); // Since sweep resets isCompleted to false
    }

    if (!_isChecked) {
      // This condition will always be false due to setState above, but keeping structure from original intent
      await storage.saveHabit(Habit(
        id: widget.habit.id,
        name: widget.habit.name,
        iconCode: widget.habit.iconCode,
        isCompleted: true,
        streak: widget.habit.streak + (wasCheckedToday ? 0 : 1),
        createdAt: widget.habit.createdAt,
      ));
    } else {
      await storage.saveHabit(Habit(
        id: widget.habit.id,
        name: widget.habit.name,
        iconCode: widget.habit.iconCode,
        isCompleted: false,
        streak: widget.habit.streak > 0 && !wasCheckedToday
            ? widget.habit.streak - 1
            : widget.habit.streak,
        createdAt: widget.habit.createdAt,
      ));
    }

    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    int displayStreak = widget.habit.streak;
    if (_isChecked && !widget.habit.isCompleted) {
      displayStreak += 1;
    }

    // Determine visual milestones based on Streak logic requirements
    Color flameColor = CupertinoColors.systemGrey;
    FontWeight textWeight = FontWeight.w500;
    BoxDecoration rowDecoration = BoxDecoration(
      border: Border(
        bottom:
            BorderSide(color: AppTheme.systemGray.withOpacity(0.2), width: 0.5),
      ),
    );

    if (displayStreak >= 100) {
      flameColor = AppTheme.growthGreen; // Phosphor green
      textWeight = FontWeight.w900; // Heavy
      rowDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.15),
            const Color(0xFFFFA500).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.systemGray.withOpacity(0.2), width: 0.5),
        ),
      );
    } else if (displayStreak >= 30) {
      flameColor = AppTheme.growthGreen; // Phosphor green
      textWeight = FontWeight.w900; // Heavy
    } else if (displayStreak >= 7) {
      flameColor = AppTheme.focusBlue; // Focus blue
    }

    return Dismissible(
      key: ValueKey(widget.habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticWrapper.heavy();
        final storage = context.read<StorageService>();
        var habits = storage.getHabits();
        habits.removeWhere((h) => h.id == widget.habit.id);
        await storage.saveAllHabits(habits);
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
            decoration: rowDecoration,
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
                    widget.habit.name,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.systemBlack,
                      fontWeight: textWeight,
                      decoration: _isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2.0,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.systemGray6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.flame_fill,
                          size: 14, color: flameColor),
                      const SizedBox(width: 4),
                      Text(
                        '$displayStreak',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
