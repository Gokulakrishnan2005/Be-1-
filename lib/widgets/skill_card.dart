import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import 'squircle_card.dart';
import 'haptic_wrapper.dart';
import 'modals/time_splitter_modal.dart';
import 'modals/retroactive_log_modal.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback onDeleted;

  const SkillCard({super.key, required this.skill, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<TimerService>();
    final storageService = context.read<StorageService>();

    final isActive = timerService.activeSkillId == skill.id;

    // Calculate total previous hours from saved sessions
    final sessions = storageService.getSessionsForSkill(skill.id);
    final totalSeconds =
        sessions.fold<int>(0, (sum, session) => sum + session.durationSeconds);

    // Add dynamically ticking current session if active
    final currentSessionSeconds =
        isActive ? timerService.currentDuration.inSeconds : 0;
    final displaySeconds = totalSeconds + currentSessionSeconds;

    // Format H:MM:SS
    final hours = displaySeconds ~/ 3600;
    final minutes = (displaySeconds % 3600) ~/ 60;
    final seconds = displaySeconds % 60;
    final timeString =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

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

    return CupertinoContextMenu(
      actions: <Widget>[
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          onPressed: () async {
            HapticWrapper.heavy();
            if (isActive) {
              // Cannot practically pause here anymore since it's continuous.
              // We'll let them switch or just let the timer keep going on whatever happens to be active,
              // but actually if they delete the active skill we must stop it.
              // For now, let's just make sure we don't call toggleTimer.
            }
            await storageService.deleteSkill(skill.id);
            await storageService.deleteSessionsForSkill(skill.id);
            Navigator.pop(context); // Close the context menu
            onDeleted();
          },
          trailingIcon: CupertinoIcons.trash,
          child: const Text('Delete Skill'),
        ),
      ],
      child: GestureDetector(
        onLongPress: skill.category == 'ENTROPY'
            ? () {
                HapticWrapper.heavy();
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => RetroactiveLogModal(
                    categoryName: skill.name,
                    onLog: (Duration duration) {
                      timerService.retroactiveLog(
                          skill.id, duration, storageService);
                    },
                  ),
                );
              }
            : null,
        child: SquircleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getIconData(skill.iconName),
                    color: isActive ? activeColor : AppTheme.systemBlack,
                    size: 28,
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticWrapper.heavy();

                      final activeId = timerService.activeSkillId;
                      final currentDur = timerService.currentDuration;

                      if (activeId != null &&
                          activeId != skill.id &&
                          currentDur.inHours >= 4) {
                        final activeSkill =
                            storageService.getSkills().firstWhere(
                                  (s) => s.id == activeId,
                                  orElse: () => Skill(
                                      id: '',
                                      name: 'Unknown',
                                      iconName: '',
                                      targetHours: 0),
                                );

                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => TimeSplitterModal(
                            oldSkillName: activeSkill.name,
                            newSkillName: skill.name,
                            totalDuration: currentDur,
                            onMachine: () {
                              timerService.switchTimer(
                                  skill.id, storageService);
                            },
                            onSplit: (oldDur, newDur) {
                              timerService.splitAndSwitchTimer(
                                  activeId, oldDur, skill.id, storageService);
                            },
                          ),
                        );
                      } else {
                        timerService.switchTimer(skill.id, storageService);
                      }
                    },
                    child: Icon(
                      isActive
                          ? CupertinoIcons.pause_circle_fill
                          : CupertinoIcons.play_circle_fill,
                      color: isActive ? activeColor : AppTheme.systemGray,
                      size: 36,
                    ),
                  )
                ],
              ),
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
                  Text(
                    timeString,
                    style: TextStyle(
                      fontFamily: 'Courier', // monospaced
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: isActive ? activeColor : AppTheme.systemBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal: ${skill.targetHours}h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.systemGray,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // A simple mapping for icons
    switch (iconName) {
      case 'book':
        return CupertinoIcons.book;
      case 'guitar':
        return CupertinoIcons.goforward_15; // mock icon
      case 'gym':
        return CupertinoIcons.heart_fill;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      default:
        return CupertinoIcons.star;
    }
  }
}
