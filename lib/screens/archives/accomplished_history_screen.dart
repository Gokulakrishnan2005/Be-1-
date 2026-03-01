import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class AccomplishedHistoryScreen extends StatelessWidget {
  const AccomplishedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    // Fetch completed tasks and success goals
    final completedTasks = storage
        .getTasks()
        .where((t) => t.isCompleted && t.completedAt != null)
        .toList();
    final successGoals = storage
        .getGoals()
        .where((g) => g.status == GoalStatus.success)
        .toList();

    // Combine into a generic list form for the chronological ledger
    final List<Map<String, dynamic>> ledger = [];

    for (var task in completedTasks) {
      ledger.add({
        'title': task.title,
        'type': 'Task',
        'date': task.completedAt!,
      });
    }

    for (var goal in successGoals) {
      // Use expiresAt as completion proxy for architecture simplicity if a specific completion date wasn't recorded,
      // though ideally a completedAt field would be best. We'll use expiresAt here.
      ledger.add({
        'title': goal.title,
        'type': 'Goal',
        'date': goal.expiresAt,
      });
    }

    // Sort Newest first
    ledger.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Accomplished'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: ledger.isEmpty
            ? Center(
                child: Text(
                  'Your history is empty.\nGo build it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: ledger.length,
                itemBuilder: (context, index) {
                  final entry = ledger[index];
                  final DateTime date = entry['date'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.pureCeramicWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.growthGreen.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            entry['type'] == 'Goal'
                                ? CupertinoIcons.flag_fill
                                : CupertinoIcons.checkmark_square_fill,
                            color: AppTheme.growthGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.systemBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completed on ${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.systemGray,
                                  ),
                                ),
                              ],
                            ),
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
