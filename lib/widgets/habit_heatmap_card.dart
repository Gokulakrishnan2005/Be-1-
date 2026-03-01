import 'package:flutter/cupertino.dart';

import '../models/habit.dart';
import '../theme/app_theme.dart';
import 'squircle_card.dart';

/// Reusable card showing a habit's name, streak, total completions, and a
/// localized GitHub-style heatmap from its completedDates.
/// Accepts optional [startDate] / [endDate] for cropping (archived habits).
class HabitHeatmapCard extends StatelessWidget {
  final Habit habit;
  final DateTime? endDate; // null = now
  final VoidCallback? onDelete; // swipe-to-delete action for archived

  const HabitHeatmapCard({
    super.key,
    required this.habit,
    this.endDate,
    this.onDelete,
  });

  String _monthAbbr(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final totalCompletions = habit.completedDates.length;
    final completedSet = Set<String>.from(habit.completedDates);

    final effectiveEnd = endDate ?? DateTime.now();
    final effectiveEndDay =
        DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day);
    final startDay = DateTime(
        habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);

    // Calculate number of weeks to show
    final totalDays = effectiveEndDay.difference(startDay).inDays + 1;
    final int todayDayIndex =
        effectiveEndDay.weekday == 7 ? 0 : effectiveEndDay.weekday;
    final numWeeks = ((totalDays + todayDayIndex) / 7).ceil().clamp(1, 52);

    const double cellSize = 10.0;
    const double cellGap = 2.0;
    const double cellRadius = 3.0;

    final card = SquircleCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                IconData(habit.iconCode,
                    fontFamily: 'CupertinoIcons',
                    fontPackage: 'cupertino_icons'),
                size: 20,
                color: AppTheme.systemBlack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.systemBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.systemGray6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.flame_fill,
                        size: 12, color: AppTheme.stateGrowth),
                    const SizedBox(width: 3),
                    Text(
                      '${habit.streak}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalCompletions done',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.systemGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Heatmap Grid
          SizedBox(
            height: (cellSize + cellGap) * 7 - cellGap,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: numWeeks,
              itemBuilder: (context, weekIndex) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: weekIndex == numWeeks - 1 ? 0 : cellGap,
                  ),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final int daysFromEnd = (numWeeks - 1 - weekIndex) * 7 +
                          (todayDayIndex - dayIndex);
                      final date =
                          effectiveEndDay.subtract(Duration(days: daysFromEnd));
                      final bool isFuture = daysFromEnd < 0;
                      final bool isBeforeStart = date.isBefore(startDay);

                      if (isFuture || isBeforeStart) {
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: EdgeInsets.only(
                              bottom: dayIndex < 6 ? cellGap : 0),
                        );
                      }

                      final dateStr =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final isCompleted = completedSet.contains(dateStr);

                      return Container(
                        width: cellSize,
                        height: cellSize,
                        margin:
                            EdgeInsets.only(bottom: dayIndex < 6 ? cellGap : 0),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.growthGreen
                              : AppTheme.systemGray6,
                          borderRadius: BorderRadius.circular(cellRadius),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),

          // Archived lifespan label
          if (endDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_monthAbbr(habit.createdAt.month)} ${habit.createdAt.year} — ${_monthAbbr(endDate!.month)} ${endDate!.year}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.systemGray,
              ),
            ),
          ],
        ],
      ),
    );

    // No swipe for active habits
    if (onDelete == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: card,
      );
    }

    // Swipe to permanently delete for archived
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: ValueKey('archive_${habit.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          final confirm = await showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: Text('Permanently delete "${habit.name}"?'),
              content: const Text(
                  'This will erase all history. This cannot be undone.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Delete Forever'),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          );
          if (confirm == true) {
            onDelete!();
          }
          return false; // we handle removal ourselves
        },
        background: Container(
          color: CupertinoColors.systemRed,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(CupertinoIcons.trash_fill,
              color: AppTheme.pureCeramicWhite, size: 28),
        ),
        child: card,
      ),
    );
  }
}
