import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show showDateRangePicker, DateTimeRange, Theme, ThemeData, ColorScheme;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';

import '../models/skill.dart';
import '../widgets/squircle_card.dart';
import '../widgets/haptic_wrapper.dart';
import 'archives/category_history_screen.dart';

class TimeAnalyticsScreen extends StatefulWidget {
  const TimeAnalyticsScreen({super.key});

  @override
  State<TimeAnalyticsScreen> createState() => _TimeAnalyticsScreenState();
}

class _TimeAnalyticsScreenState extends State<TimeAnalyticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  // Data
  double _growthSeconds = 0;
  double _maintenanceSeconds = 0;
  double _entropySeconds = 0;
  double _untrackedSeconds = 0;
  double _totalPossibleSeconds = 0;
  List<MapEntry<DateTime, Map<String, double>>> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateStats();
    });
  }

  Future<void> _selectDateRange() async {
    HapticWrapper.light();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.systemBlack,
              onPrimary: AppTheme.pureCeramicWhite,
              surface: AppTheme.systemGray6,
              onSurface: AppTheme.systemBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _calculateStats();
      });
    }
  }

  void _calculateStats() {
    final storageUser = context.read<StorageService>();
    final allSessions = storageUser.getSessions();
    final allSkills = storageUser.getSkills();

    // Reset stats
    double gSec = 0;
    double mSec = 0;
    double eSec = 0;

    // We want the end of day for the end date to include all of today.
    final effectiveEnd =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    final effectiveStart =
        DateTime(_startDate.year, _startDate.month, _startDate.day);

    // Calculate total possible hours for the date range
    final numberOfDays = _endDate.difference(_startDate).inDays + 1;
    final totalPossible = numberOfDays * 24.0 * 3600.0;

    Map<DateTime, Map<String, double>> groupedByDay = {};

    for (final session in allSessions) {
      // Must fall in range
      if (session.startTime.isAfter(effectiveEnd) ||
          session.endTime.isBefore(effectiveStart)) {
        continue;
      }

      // Bound to the user-selected range
      DateTime sessStart = session.startTime.isBefore(effectiveStart)
          ? effectiveStart
          : session.startTime;
      DateTime sessEnd = session.endTime.isAfter(effectiveEnd)
          ? effectiveEnd
          : session.endTime;

      // Find skill category
      final skill = allSkills.firstWhere((s) => s.id == session.skillId,
          orElse: () => Skill(id: '', name: '', iconName: '', targetHours: 0));
      final category = skill.category;

      // ─── MIDNIGHT SESSION CLIPPING ─────────────────────────────
      // Walk day-by-day, clipping at midnight boundaries
      DateTime cursor = sessStart;
      while (cursor.isBefore(sessEnd)) {
        final dayStart = DateTime(cursor.year, cursor.month, cursor.day);
        final nextMidnight = dayStart.add(const Duration(days: 1));

        final clipStart = cursor;
        final clipEnd = nextMidnight.isBefore(sessEnd) ? nextMidnight : sessEnd;
        final duration = clipEnd.difference(clipStart).inSeconds.toDouble();

        if (duration > 0) {
          // Accumulate totals
          if (category == 'MAINTENANCE') {
            mSec += duration;
          } else if (category == 'ENTROPY') {
            eSec += duration;
          } else {
            gSec += duration;
          }

          // Assign to this day's bucket
          groupedByDay.putIfAbsent(
              dayStart, () => {'GROWTH': 0, 'MAINTENANCE': 0, 'ENTROPY': 0});

          if (category == 'MAINTENANCE') {
            groupedByDay[dayStart]!['MAINTENANCE'] =
                groupedByDay[dayStart]!['MAINTENANCE']! + duration;
          } else if (category == 'ENTROPY') {
            groupedByDay[dayStart]!['ENTROPY'] =
                groupedByDay[dayStart]!['ENTROPY']! + duration;
          } else {
            groupedByDay[dayStart]!['GROWTH'] =
                groupedByDay[dayStart]!['GROWTH']! + duration;
          }
        }

        cursor = nextMidnight;
      }
    }

    // Sort descending by date (newest first)
    final sortedDaily = groupedByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Calculate untracked time
    final totalTracked = gSec + mSec + eSec;
    final double untracked =
        (totalPossible - totalTracked).clamp(0.0, totalPossible).toDouble();

    setState(() {
      _growthSeconds = gSec;
      _maintenanceSeconds = mSec;
      _entropySeconds = eSec;
      _untrackedSeconds = untracked;
      _totalPossibleSeconds = totalPossible;
      _dailyStats = sortedDaily;
    });
  }

  String _formatDuration(double totalSeconds) {
    if (totalSeconds == 0) return "0h";
    int hours = totalSeconds ~/ 3600;
    int minutes = ((totalSeconds % 3600) / 60).round();

    if (hours > 0 && minutes > 0) return "${hours}h ${minutes}m";
    if (hours > 0) return "${hours}h";
    return "${minutes}m";
  }

  String _getDateRangeLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysDiff = _endDate.difference(_startDate).inDays;

    if (_endDate.year == today.year &&
        _endDate.month == today.month &&
        _endDate.day == today.day) {
      if (daysDiff == 6) return "Last 7 Days";
      if (daysDiff == 29) return "Last 30 Days";
    }

    final format = DateFormat('MMM d');
    return "${format.format(_startDate)} - ${format.format(_endDate)}";
  }

  @override
  Widget build(BuildContext context) {
    final totalTracked = _growthSeconds + _maintenanceSeconds + _entropySeconds;
    final hasData = totalTracked > 0;

    // Ratios based on TOTAL POSSIBLE (24h * days), NOT tracked time
    final growthRatio = _totalPossibleSeconds > 0
        ? (_growthSeconds / _totalPossibleSeconds) * 100
        : 0.0;
    final maintenanceRatio = _totalPossibleSeconds > 0
        ? (_maintenanceSeconds / _totalPossibleSeconds) * 100
        : 0.0;
    final entropyRatio = _totalPossibleSeconds > 0
        ? (_entropySeconds / _totalPossibleSeconds) * 100
        : 0.0;
    final untrackedRatio = _totalPossibleSeconds > 0
        ? (_untrackedSeconds / _totalPossibleSeconds) * 100
        : 0.0;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.systemGray6,
        border: null,
        middle: Text('Time Analytics'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    color: AppTheme.systemGray.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    onPressed: _selectDateRange,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.calendar,
                            size: 18, color: AppTheme.systemBlack),
                        const SizedBox(width: 8),
                        Text(
                          _getDateRangeLabel(),
                          style: const TextStyle(
                            color: AppTheme.systemBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down,
                            size: 14, color: AppTheme.systemBlack),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // The Life Ring (Hero)
              if (!hasData)
                Container(
                  height: 240,
                  alignment: Alignment.center,
                  child: const Text(
                    'No reality logged for this period.',
                    style: TextStyle(color: AppTheme.systemGray, fontSize: 16),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  width: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 90,
                            startDegreeOffset: 270,
                            sections: [
                              if (_growthSeconds > 0)
                                PieChartSectionData(
                                  color: AppTheme.stateGrowth,
                                  value: _growthSeconds,
                                  title: '',
                                  radius: 24,
                                ),
                              if (_maintenanceSeconds > 0)
                                PieChartSectionData(
                                  color: AppTheme.stateMaintenance,
                                  value: _maintenanceSeconds,
                                  title: '',
                                  radius: 24,
                                ),
                              if (_entropySeconds > 0)
                                PieChartSectionData(
                                  color: AppTheme.stateEntropy,
                                  value: _entropySeconds,
                                  title: '',
                                  radius: 24,
                                ),
                              if (_untrackedSeconds > 0)
                                PieChartSectionData(
                                  color: AppTheme.voidBlack.withOpacity(0.12),
                                  value: _untrackedSeconds,
                                  title: '',
                                  radius: 24,
                                ),
                            ]),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${growthRatio.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.systemBlack,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const Text(
                            'Growth Score',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.systemGray,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 48),

              // Breakdown Cards (4 cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStatCard(
                        'Growth',
                        _formatDuration(_growthSeconds),
                        '${growthRatio.toStringAsFixed(1)}%',
                        AppTheme.stateGrowth,
                        CupertinoIcons.graph_square,
                        'GROWTH'),
                    const SizedBox(width: 8),
                    _buildStatCard(
                        'Maint.',
                        _formatDuration(_maintenanceSeconds),
                        '${maintenanceRatio.toStringAsFixed(1)}%',
                        AppTheme.stateMaintenance,
                        CupertinoIcons.wrench,
                        'MAINTENANCE'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStatCard(
                        'Entropy',
                        _formatDuration(_entropySeconds),
                        '${entropyRatio.toStringAsFixed(1)}%',
                        AppTheme.stateEntropy,
                        CupertinoIcons.flame,
                        'ENTROPY'),
                    const SizedBox(width: 8),
                    _buildUntrackedCard(
                      _formatDuration(_untrackedSeconds),
                      '${untrackedRatio.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // History List
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Daily Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_dailyStats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No daily data available.',
                      style: TextStyle(color: AppTheme.systemGray)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dailyStats.length,
                  itemBuilder: (context, index) {
                    final entry = _dailyStats[index];
                    final date = entry.key;
                    final stats = entry.value;

                    final dGrowth = stats['GROWTH'] ?? 0;
                    final dMaint = stats['MAINTENANCE'] ?? 0;
                    final dEntropy = stats['ENTROPY'] ?? 0;
                    final dTotal = dGrowth + dMaint + dEntropy;

                    if (dTotal <= 0) return const SizedBox.shrink();

                    // Untracked for this day
                    final dUntracked = (86400.0 - dTotal).clamp(0, 86400.0);

                    final dateFormat = DateFormat('E, MMM d');

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateFormat.format(date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(_formatDuration(dTotal),
                                  style: const TextStyle(
                                      color: AppTheme.systemGray,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 8,
                              child: Row(
                                children: [
                                  if (dGrowth > 0)
                                    Expanded(
                                      flex: (dGrowth * 1000).toInt(),
                                      child: Container(
                                          color: AppTheme.stateGrowth),
                                    ),
                                  if (dMaint > 0)
                                    Expanded(
                                      flex: (dMaint * 1000).toInt(),
                                      child: Container(
                                          color: AppTheme.stateMaintenance),
                                    ),
                                  if (dEntropy > 0)
                                    Expanded(
                                      flex: (dEntropy * 1000).toInt(),
                                      child: Container(
                                          color: AppTheme.stateEntropy),
                                    ),
                                  if (dUntracked > 0)
                                    Expanded(
                                      flex: (dUntracked * 1000).toInt(),
                                      child: Container(
                                          color: AppTheme.voidBlack
                                              .withOpacity(0.08)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String duration, String percent,
      Color color, IconData icon, String categoryIdentifier) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticWrapper.light();
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => CategoryHistoryScreen(
                  category: categoryIdentifier, themeColor: color),
            ),
          );
        },
        child: SquircleCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                percent,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.systemGray,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUntrackedCard(String duration, String percent) {
    return Expanded(
      child: SquircleCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(CupertinoIcons.circle,
                color: AppTheme.voidBlack.withOpacity(0.3), size: 24),
            const SizedBox(height: 12),
            Text(
              duration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              percent,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.voidBlack.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Untracked',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.systemGray,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}
