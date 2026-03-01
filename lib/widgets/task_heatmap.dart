import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';

/// Aggregate Task & Habit completion heatmap — GitHub-style grid.
/// Color scale: Phosphor Green (#34C759) based on daily completion %.
class TaskHeatmap extends StatefulWidget {
  const TaskHeatmap({super.key});

  @override
  State<TaskHeatmap> createState() => _TaskHeatmapState();
}

class _TaskHeatmapState extends State<TaskHeatmap> {
  OverlayEntry? _tooltipEntry;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _removeTooltip();
    _scrollController.dispose();
    super.dispose();
  }

  void _showTooltip(
      BuildContext context, int completed, int total, GlobalKey key) {
    _removeTooltip();
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _removeTooltip,
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0x00000000),
              ),
            ),
            Positioned(
              left: position.dx - 20,
              top: position.dy - 34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.systemBlack.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completed/$total done',
                  style: const TextStyle(
                    color: AppTheme.pureCeramicWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_tooltipEntry!);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

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
    final storage = context.watch<StorageService>();
    final allTasks = storage.getTasks();
    final allHabits = storage.getHabits().where((h) => !h.isArchived).toList();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final int todayDayIndex = now.weekday == 7 ? 0 : now.weekday;

    // Build daily completion data: Map<daysAgo, {completed, total}>
    final Map<int, List<int>> dailyData = {}; // [completed, total]

    for (int daysAgo = 0; daysAgo < 366; daysAgo++) {
      final date = todayStart.subtract(Duration(days: daysAgo));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      int completed = 0;
      int total = 0;

      // Tasks completed on this date
      for (final task in allTasks) {
        if (task.completedAt != null) {
          final taskDay = DateTime(task.completedAt!.year,
              task.completedAt!.month, task.completedAt!.day);
          if (taskDay.year == date.year &&
              taskDay.month == date.month &&
              taskDay.day == date.day) {
            completed++;
            total++;
          }
        }
        // Count tasks created on this date as part of total
        final createdDay = DateTime(
            task.createdAt.year, task.createdAt.month, task.createdAt.day);
        if (createdDay.year == date.year &&
            createdDay.month == date.month &&
            createdDay.day == date.day &&
            task.completedAt == null) {
          total++;
        }
      }

      // Habits completed on this date
      for (final habit in allHabits) {
        // Only count habits that existed on this date
        final habitCreated = DateTime(
            habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
        if (!date.isBefore(habitCreated)) {
          total++;
          if (habit.completedDates.contains(dateStr)) {
            completed++;
          }
          // Today: check isCompleted flag
          if (daysAgo == 0 && habit.isCompleted) {
            completed++;
            // Don't double count — only if not already in completedDates
            if (habit.completedDates.contains(todayStr)) {
              completed--; // Was already counted above
            }
          }
        }
      }

      if (total > 0) {
        dailyData[daysAgo] = [completed, total];
      }
    }

    const int numWeeks = 52;
    const int daysPerWeek = 7;
    const double cellSize = 12.0;
    const double cellGap = 3.0;
    const double cellRadius = 4.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('M',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('W',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('F',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
                Text('',
                    style: TextStyle(fontSize: 10, color: AppTheme.systemGray)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: numWeeks,
              itemBuilder: (context, weekIndex) {
                final int daysToWeekStart =
                    (numWeeks - 1 - weekIndex) * 7 + todayDayIndex;
                final weekStartDate =
                    todayStart.subtract(Duration(days: daysToWeekStart));
                final prevWeekStartDate =
                    weekStartDate.subtract(const Duration(days: 7));

                String monthLabel = '';
                if (weekStartDate.month != prevWeekStartDate.month) {
                  monthLabel = _monthAbbr(weekStartDate.month);
                }

                return Padding(
                  padding: EdgeInsets.only(
                    right: weekIndex == numWeeks - 1 ? 16 : cellGap,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 16,
                        child: Text(
                          monthLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.systemGray,
                          ),
                        ),
                      ),
                      ...List.generate(daysPerWeek, (dayIndex) {
                        final int daysFromEnd = (numWeeks - 1 - weekIndex) * 7 +
                            (todayDayIndex - dayIndex);
                        final bool isFuture = daysFromEnd < 0;
                        final data = isFuture ? null : dailyData[daysFromEnd];

                        Color cellColor;
                        int completed = 0;
                        int total = 0;

                        if (isFuture) {
                          cellColor = const Color(0x00000000);
                        } else if (data == null) {
                          cellColor = AppTheme.systemGray6;
                        } else {
                          completed = data[0];
                          total = data[1];
                          final ratio = total > 0 ? completed / total : 0.0;

                          if (ratio <= 0) {
                            cellColor = AppTheme.systemGray6;
                          } else if (ratio <= 0.33) {
                            cellColor = AppTheme.growthGreen.withOpacity(0.3);
                          } else if (ratio <= 0.66) {
                            cellColor = AppTheme.growthGreen.withOpacity(0.6);
                          } else {
                            cellColor = AppTheme.growthGreen;
                          }
                        }

                        final cellKey = GlobalKey();

                        return GestureDetector(
                          key: cellKey,
                          onTap: isFuture
                              ? null
                              : () {
                                  HapticWrapper.light();
                                  _showTooltip(
                                      context, completed, total, cellKey);
                                },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.only(
                                bottom:
                                    dayIndex < daysPerWeek - 1 ? cellGap : 0),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(cellRadius),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
