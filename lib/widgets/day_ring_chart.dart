import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';

class DayRingChart extends StatelessWidget {
  const DayRingChart({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = context.watch<StorageService>();
    final timerService = context.watch<TimerService>();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final allSessions = storageService
        .getSessions()
        .where((s) =>
            s.startTime.isAfter(startOfDay) || (s.endTime.isAfter(startOfDay)))
        .toList();
    final allSkills = storageService.getSkills();

    double growthSeconds = 0;
    double maintainSeconds = 0;
    double entropySeconds = 0;

    // Helper to add time to category
    void addTime(String category, double seconds) {
      if (category == 'MAINTENANCE') {
        maintainSeconds += seconds;
      } else if (category == 'ENTROPY') {
        entropySeconds += seconds;
      } else {
        growthSeconds += seconds;
      }
    }

    // Process logged sessions for today
    for (final session in allSessions) {
      // Find skill
      final skill = allSkills.firstWhere((s) => s.id == session.skillId,
          orElse: () => Skill(id: '', name: '', iconName: '', targetHours: 0));

      // Calculate how much of this session was actually today
      DateTime sessionStart = session.startTime.isBefore(startOfDay)
          ? startOfDay
          : session.startTime;
      DateTime sessionEnd = session.endTime;
      final duration = sessionEnd.difference(sessionStart).inSeconds.toDouble();

      if (duration > 0) {
        addTime(skill.category, duration);
      }
    }

    // Process active timer if any
    if (timerService.isTimerActive && timerService.activeStartTime != null) {
      final activeSkillId = timerService.activeSkillId;
      final skill = allSkills.firstWhere((s) => s.id == activeSkillId,
          orElse: () => Skill(id: '', name: '', iconName: '', targetHours: 0));

      DateTime sessionStart = timerService.activeStartTime!.isBefore(startOfDay)
          ? startOfDay
          : timerService.activeStartTime!;
      final duration =
          DateTime.now().difference(sessionStart).inSeconds.toDouble();

      if (duration > 0) {
        addTime(skill.category, duration);
      }
    }

    final totalSeconds = growthSeconds + maintainSeconds + entropySeconds;
    final hasData = totalSeconds > 0;
    final growthRatio = hasData ? (growthSeconds / totalSeconds) * 100 : 0.0;

    return SizedBox(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                startDegreeOffset: 270, // 12 o'clock
                sections: hasData
                    ? [
                        if (growthSeconds > 0)
                          PieChartSectionData(
                            color: AppTheme.stateGrowth,
                            value: growthSeconds,
                            title: '',
                            radius: 12,
                          ),
                        if (maintainSeconds > 0)
                          PieChartSectionData(
                            color: AppTheme.stateMaintenance,
                            value: maintainSeconds,
                            title: '',
                            radius: 12,
                          ),
                        if (entropySeconds > 0)
                          PieChartSectionData(
                            color: AppTheme.stateEntropy,
                            value: entropySeconds,
                            title: '',
                            radius: 12,
                          ),
                      ]
                    : [
                        PieChartSectionData(
                          color: AppTheme.systemGray6,
                          value: 1,
                          title: '',
                          radius: 12,
                        )
                      ]),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasData ? '${growthRatio.toStringAsFixed(0)}%' : '--%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.systemBlack,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Growth',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.systemGray,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
