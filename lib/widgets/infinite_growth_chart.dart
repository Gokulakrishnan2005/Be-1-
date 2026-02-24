import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class InfiniteGrowthChart extends StatelessWidget {
  const InfiniteGrowthChart({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final sessions = storage.getSessions();
    
    // Sort chronologically
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Aggregate total duration by day
    final Map<int, int> dailyDuration = {};
    for (var session in sessions) {
      final dayCode = session.startTime.difference(DateTime.now()).inDays;
      dailyDuration[dayCode] = (dailyDuration[dayCode] ?? 0) + session.durationSeconds;
    }

    if (dailyDuration.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No practice data yet.\nStart a timer to see growth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
        ),
      );
    }

    final sortedDays = dailyDuration.keys.toList()..sort();
    List<FlSpot> spots = [];
    double cumulativeHours = 0;
    
    for (int day in sortedDays) {
      cumulativeHours += dailyDuration[day]! / 3600.0;
      spots.add(FlSpot(day.toDouble(), cumulativeHours));
    }

    if (spots.length == 1) {
      spots.insert(0, FlSpot(spots.first.x - 1, 0));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, right: 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.focusBlue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.focusBlue.withOpacity(0.15),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false), // Static visual
        ),
      ),
    );
  }
}
