import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import 'squircle_card.dart';
import 'haptic_wrapper.dart';
import 'modals/edit_skill_modal.dart';
import 'modals/tactical_position_sheet.dart';
import 'modals/multi_split_audit_modal.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback onDeleted;

  const SkillCard({super.key, required this.skill, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    final storageService = context.read<StorageService>();
    final strictMode = storageService.getStrictMode();

    final isActive = timerService.activeSkillId == skill.id;

    // Calculate total previous hours from saved sessions
    final sessions = storageService.getSessionsForSkill(skill.id);
    final totalSeconds =
        sessions.fold<int>(0, (sum, session) => sum + session.durationSeconds);

    // Add dynamically ticking current session if active
    final currentSessionSeconds =
        isActive ? timerService.currentDuration.inSeconds : 0;
    final displaySeconds = totalSeconds + currentSessionSeconds;

    Color activeColor;
    switch (skill.category) {
      case 'MAINTENANCE':
        activeColor = AppTheme.stateMaintenance;
        break;
      case 'ENTROPY':
        activeColor = AppTheme.stateEntropy;
        break;
      case 'GROWTH':
      default:
        activeColor = AppTheme.stateGrowth;
    }

    // Determine play/pause icon based on strict mode
    IconData actionIcon;
    if (isActive) {
      if (strictMode) {
        actionIcon = CupertinoIcons.checkmark_circle_fill;
      } else {
        actionIcon = CupertinoIcons.pause_circle_fill;
      }
    } else {
      actionIcon = CupertinoIcons.play_circle_fill;
    }

    // ─── TODAY'S TOTAL ─────────────────────────────────────────
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final todaySessions = sessions
        .where((s) =>
            s.startTime.isAfter(startOfToday) ||
            s.endTime.isAfter(startOfToday))
        .toList();
    int todaySeconds = 0;
    for (final s in todaySessions) {
      final clippedStart =
          s.startTime.isBefore(startOfToday) ? startOfToday : s.startTime;
      todaySeconds += s.endTime.difference(clippedStart).inSeconds;
    }
    // Add live session time if active
    if (isActive) {
      todaySeconds += currentSessionSeconds;
    }

    // Format Today HH:MM:SS
    final tH = todaySeconds ~/ 3600;
    final tM = (todaySeconds % 3600) ~/ 60;
    final tS = todaySeconds % 60;
    final todayString =
        '${tH.toString().padLeft(2, '0')} : ${tM.toString().padLeft(2, '0')} : ${tS.toString().padLeft(2, '0')}';

    // Session time (current only, resets on pause)
    final sessionMinutes = currentSessionSeconds ~/ 60;
    final sessionText = isActive ? '${sessionMinutes}m' : '0m';

    // Total hours across all time
    final totalHours = displaySeconds ~/ 3600;

    return CupertinoContextMenu(
      actions: <Widget>[
        // 1. Audit Last Session
        CupertinoContextMenuAction(
          onPressed: () {
            HapticWrapper.medium();
            Navigator.pop(context);
            _openLastSessionAudit(context, storageService, timerService);
          },
          trailingIcon: CupertinoIcons.doc_text_search,
          child: const Text('Audit Last Session'),
        ),
        // 2. Edit Skill
        CupertinoContextMenuAction(
          onPressed: () {
            HapticWrapper.medium();
            Navigator.pop(context);
            showCupertinoModalPopup(
              context: context,
              builder: (context) => EditSkillModal(
                skill: skill,
                onEdited: onDeleted,
              ),
            );
          },
          trailingIcon: CupertinoIcons.pencil,
          child: const Text('Edit Skill'),
        ),
        // 3. Change Position
        CupertinoContextMenuAction(
          onPressed: () {
            HapticWrapper.medium();
            Navigator.pop(context);
            showCupertinoModalPopup(
              context: context,
              builder: (ctx) => TacticalPositionSheet(
                skill: skill,
                onChanged: onDeleted,
              ),
            );
          },
          trailingIcon: CupertinoIcons.arrow_up_arrow_down,
          child: const Text('Change Position'),
        ),
        // 4. Delete Skill
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          onPressed: () async {
            HapticWrapper.heavy();
            await storageService.deleteSkill(skill.id);
            await storageService.deleteSessionsForSkill(skill.id);
            Navigator.pop(context);
            onDeleted();
          },
          trailingIcon: CupertinoIcons.trash,
          child: const Text('Delete Skill'),
        ),
      ],
      child: SquircleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ─── TOP ROW: Icon + Play/Pause ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getIconData(skill.iconName),
                  color: isActive ? activeColor : AppTheme.systemBlack,
                  size: 28,
                ),
                GestureDetector(
                  onTap: () => _handlePlayTap(context, timerService,
                      storageService, isActive, strictMode),
                  child: Icon(
                    actionIcon,
                    color: isActive ? activeColor : AppTheme.systemGray,
                    size: 36,
                  ),
                )
              ],
            ),
            // ─── MIDDLE: Skill Name ──────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.systemBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // ─── BIG: Today's Total (ticks when active) ──
                Text(
                  todayString,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: isActive ? activeColor : AppTheme.systemBlack,
                  ),
                ),
                const SizedBox(height: 4),
                // ─── SMALL METADATA: Session + Total Goal ──
                Text(
                  'Session: $sessionText  •  Total: ${totalHours}h',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.systemGray,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ─── PLAY BUTTON TAP LOGIC ──────────────────────────────────
  void _handlePlayTap(BuildContext context, TimerService timerService,
      StorageService storageService, bool isActive, bool strictMode) {
    HapticWrapper.heavy();

    final activeId = timerService.activeSkillId;
    final currentDur = timerService.currentDuration;

    // If tapping the currently active card
    if (isActive) {
      if (!strictMode) {
        // Strict OFF: pause the timer
        timerService.pauseTimer(storageService);
        onDeleted(); // Refresh
      }
      // Strict ON: no-op
      return;
    }

    // If switching FROM another timer — always open Multi-Split Auditor
    if (activeId != null && activeId != skill.id) {
      final allSkills = storageService.getSkills();
      final activeSkill = allSkills.firstWhere(
        (s) => s.id == activeId,
        orElse: () =>
            Skill(id: '', name: 'Unknown', iconName: '', targetHours: 0),
      );

      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => MultiSplitAuditModal(
          originalSkill: activeSkill,
          totalDuration: currentDur,
          allSkills: allSkills,
          onConfirm: (splits) {
            timerService.multiSplitAuditAndSwitch(
                activeId, splits, skill.id, storageService);
            onDeleted(); // Refresh
          },
        ),
      );
      return;
    }

    // Starting fresh (no timer was running)
    timerService.switchTimer(skill.id, storageService, strictMode: strictMode);
  }

  // ─── AUDIT LAST SESSION ─────────────────────────────────────
  void _openLastSessionAudit(BuildContext context,
      StorageService storageService, TimerService timerService) {
    final sessions = storageService.getSessionsForSkill(skill.id);
    if (sessions.isEmpty) {
      _showNoSessionAlert(context);
      return;
    }

    // Get the most recent completed session
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    final lastSession = sessions.first;
    final duration = Duration(seconds: lastSession.durationSeconds);

    if (duration.inMinutes < 1) {
      _showNoSessionAlert(context);
      return;
    }

    final allSkills = storageService.getSkills();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => MultiSplitAuditModal(
        originalSkill: skill,
        totalDuration: duration,
        allSkills: allSkills,
        onConfirm: (splits) {
          timerService.auditLastSession(
              skill.id, lastSession.id, splits, storageService);
          onDeleted(); // Refresh
        },
      ),
    );
  }

  void _showNoSessionAlert(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('No Session Found'),
        content: const Text(
            'There are no completed sessions to audit for this skill.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'book':
        return CupertinoIcons.book;
      case 'guitar':
        return CupertinoIcons.goforward_15;
      case 'gym':
        return CupertinoIcons.heart_fill;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      default:
        return CupertinoIcons.star;
    }
  }
}
