import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/haptic_wrapper.dart';

class UnfinishedGoalsScreen extends StatelessWidget {
  const UnfinishedGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    // Fetch goals that expired and haven't succeeded
    final failedGoals =
        storage.getGoals().where((g) => g.status == GoalStatus.failed).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Unfinished Goals'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: failedGoals.isEmpty
            ? Center(
                child: Text(
                  'No unfinished goals.\nYou are executing perfectly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: failedGoals.length,
                itemBuilder: (context, index) {
                  final goal = failedGoals[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.pureCeramicWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.systemGray.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to reach ${goal.targetValue.toStringAsFixed(0)} ${goal.unit} by ${goal.expiresAt.month}/${goal.expiresAt.day}/${goal.expiresAt.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.systemGray.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.all(8),
                            onPressed: () async {
                              HapticWrapper.heavy();
                              final duration =
                                  goal.expiresAt.difference(goal.createdAt);
                              final storage = context.read<StorageService>();
                              final revivedGoal = Goal(
                                id: goal.id,
                                title: goal.title,
                                targetValue: goal.targetValue,
                                currentValue: goal.currentValue,
                                unit: goal.unit,
                                type: goal.type,
                                status: GoalStatus.active,
                                createdAt: DateTime.now(),
                                expiresAt: DateTime.now().add(duration),
                              );
                              await storage.saveGoal(revivedGoal);
                            },
                            child: const Icon(
                                CupertinoIcons.arrow_counterclockwise,
                                color: AppTheme.focusBlue),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
