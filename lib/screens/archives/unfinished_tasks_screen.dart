import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class UnfinishedTasksScreen extends StatelessWidget {
  const UnfinishedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    // Fetch tasks that were archived but not completed
    var tasks = storage
        .getTasks()
        .where((t) => t.isArchived && !t.isCompleted)
        .toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Unfinished Tasks'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: tasks.isEmpty
            ? Center(
                child: Text(
                  'No unfinished tasks.\nYou swept the board.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.systemGray, // Ghostly muted text
                              decoration: TextDecoration
                                  .lineThrough, // Represents past failure to complete
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Missed on ${task.createdAt.month}/${task.createdAt.day}/${task.createdAt.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.systemGray.withOpacity(0.8),
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
