import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../widgets/skill_analytics_heatmap.dart';
import '../widgets/data_portability.dart';
import '../widgets/squircle_card.dart';
import 'archives/accomplished_history_screen.dart';
import 'archives/unfinished_goals_screen.dart';
import 'archives/unfinished_tasks_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    // Sum total duration of all sessions
    final sessions = storage.getSessions();
    final totalSeconds =
        sessions.fold<int>(0, (sum, sess) => sum + sess.durationSeconds);
    final totalHoursStr = (totalSeconds / 3600.0).toStringAsFixed(1);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                    left: 24.0, right: 24.0, top: 40.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: AppTheme.systemBlack,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),

              // Infinite Growth Chart -> 10,000-Hour Heatmap
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Skill Analytics',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SquircleCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const SkillAnalyticsHeatmap(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Focus Hours',
                                style: TextStyle(color: AppTheme.systemGray)),
                            Text(
                              totalHoursStr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Group 1: Archives
              CupertinoListSection.insetGrouped(
                header: const Text('THE ARCHIVES',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Accomplished History'),
                    leading: const Icon(CupertinoIcons.checkmark_seal_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              const AccomplishedHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Unfinished Goals'),
                    leading: const Icon(CupertinoIcons.flag_slash_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const UnfinishedGoalsScreen(),
                        ),
                      );
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Unfinished Tasks'),
                    leading: const Icon(
                        CupertinoIcons.square_stack_3d_down_right_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const UnfinishedTasksScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Group 2: Future Purchases
              CupertinoListSection.insetGrouped(
                header: const Text('FUTURE ASSETS',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Wishlist'),
                    leading: const Icon(CupertinoIcons.star_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const WishlistScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const DataPortability(),

              const SizedBox(height: 48),

              Center(
                child: Text(
                  '1% Better OS v1.0.0\nLocal First, Always.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.systemGray.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
