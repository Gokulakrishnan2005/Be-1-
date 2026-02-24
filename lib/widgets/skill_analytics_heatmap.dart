import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'haptic_wrapper.dart';

class SkillAnalyticsHeatmap extends StatefulWidget {
  const SkillAnalyticsHeatmap({super.key});

  @override
  State<SkillAnalyticsHeatmap> createState() => _SkillAnalyticsHeatmapState();
}

class _SkillAnalyticsHeatmapState extends State<SkillAnalyticsHeatmap> {
  OverlayEntry? _tooltipEntry;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Auto-scroll to the end (most recent day) after layout
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

  void _showTooltip(BuildContext context, int seconds, GlobalKey key) {
    _removeTooltip();

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    int hours = seconds ~/ 3600;
    int mins = (seconds % 3600) ~/ 60;

    String timeStr = '';
    if (hours > 0) timeStr += '${hours}h ';
    if (mins > 0 || hours == 0) timeStr += '${mins}m';

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
              left: position.dx - 20, // rough centering
              top: position.dy - 34,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.systemBlack.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timeStr.trim(),
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
    final sessions = storage.getSessions();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final int todayDayIndex =
        now.weekday == 7 ? 0 : now.weekday; // Sun=0, Mon=1..

    final Map<int, int> dailyDuration = {};
    for (var session in sessions) {
      final sessionDay = DateTime(session.startTime.year,
          session.startTime.month, session.startTime.day);
      final daysAgo = todayStart.difference(sessionDay).inDays;
      if (daysAgo >= 0 && daysAgo < 366) {
        dailyDuration[daysAgo] =
            (dailyDuration[daysAgo] ?? 0) + session.durationSeconds;
      }
    }

    const int numWeeks = 52;
    const int daysPerWeek = 7;
    const double cellSize = 12.0;
    const double cellGap = 3.0;
    const double cellRadius = 3.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-Axis Labels
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0,
                right: 8.0,
                top: 16.0), // top padding pushes below month labels
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Sun (0)
                Text('M',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Mon (1)
                Text('',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Tue (2)
                Text('W',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Wed (3)
                Text('',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Thu (4)
                Text('F',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Fri (5)
                Text('',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.systemGray)), // Sat (6)
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
                      // Month Label
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
                      // The 7 Days
                      ...List.generate(daysPerWeek, (dayIndex) {
                        final int daysFromEnd = (numWeeks - 1 - weekIndex) * 7 +
                            (todayDayIndex - dayIndex);
                        final bool isFuture = daysFromEnd < 0;
                        final int durationSeconds =
                            isFuture ? 0 : (dailyDuration[daysFromEnd] ?? 0);

                        Color cellColor;
                        if (isFuture) {
                          cellColor = const Color(
                              0x00000000); // transparent so it bounds the current day nicely
                        } else if (durationSeconds == 0) {
                          cellColor = AppTheme.systemGray6;
                        } else if (durationSeconds < 3600) {
                          cellColor = AppTheme.growthGreen.withOpacity(0.4);
                        } else {
                          cellColor = AppTheme.growthGreen;
                        }

                        final cellKey = GlobalKey();

                        return GestureDetector(
                          key: cellKey,
                          onTap: isFuture
                              ? null
                              : () {
                                  HapticWrapper.light();
                                  _showTooltip(
                                      context, durationSeconds, cellKey);
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
