import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../data/daily_quotes.dart';
import '../widgets/data_portability.dart';
import 'archives/transaction_history_screen.dart';
import 'archives/accomplished_history_screen.dart';
import 'archives/unfinished_goals_screen.dart';
import 'archives/unfinished_tasks_screen.dart';
import 'time_analytics_screen.dart';
import 'habit_analytics_screen.dart';
import 'wishlist_screen.dart';
import 'vault_pin_screen.dart';
import 'journal_screen.dart';
import 'experience_board_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final strictMode = storage.getStrictMode();
    final userName = storage.getUserName();
    final dobStr = storage.getUserDob();
    final quote = DailyQuotes.today;

    String headerText = 'Profile';
    if (userName.isNotEmpty) {
      if (dobStr != null) {
        final age = _calculateAge(DateTime.parse(dobStr));
        headerText = '$userName, $age';
      } else {
        headerText = userName;
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity Header
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24.0, top: 40.0, bottom: 8.0),
                child: Text(
                  headerText,
                  style: const TextStyle(
                    color: AppTheme.systemBlack,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),

              // Daily Quote
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.systemGray.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${quote['q']}"',
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.systemBlack,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '— ${quote['a']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.systemGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Life Tools
              CupertinoListSection.insetGrouped(
                header: const Text('LIFE TOOLS',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Journal'),
                    leading: const Icon(CupertinoIcons.book_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const JournalScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('My Credentials'),
                    leading: const Icon(CupertinoIcons.lock_shield_fill,
                        color: AppTheme.focusBlue),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const VaultPinScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('Experience Board'),
                    leading: const Icon(CupertinoIcons.map_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const ExperienceBoardScreen())),
                  ),
                ],
              ),

              // Analytics Section
              CupertinoListSection.insetGrouped(
                header: const Text('ANALYTICS',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Time Analytics'),
                    leading: const Icon(CupertinoIcons.chart_pie_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const TimeAnalyticsScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('Habit Analytics'),
                    leading: const Icon(CupertinoIcons.flame_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const HabitAnalyticsScreen())),
                  ),
                ],
              ),

              // Preferences
              CupertinoListSection.insetGrouped(
                header: const Text('PREFERENCES',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Strict 24/7 Tracking'),
                    subtitle: Text(
                      strictMode
                          ? 'ON: Time never stops. Switching activities is continuous.'
                          : 'OFF: You can pause timers. Unmeasured time shows as Untracked.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.systemGray,
                      ),
                    ),
                    trailing: CupertinoSwitch(
                      value: strictMode,
                      activeTrackColor: AppTheme.stateGrowth,
                      onChanged: (value) {
                        storage.setStrictMode(value);
                      },
                    ),
                  ),
                ],
              ),

              // Archives
              CupertinoListSection.insetGrouped(
                header: const Text('THE ARCHIVES',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.systemGray)),
                children: [
                  CupertinoListTile(
                    title: const Text('Income / Expense Ledger'),
                    leading: const Icon(CupertinoIcons.creditcard_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const TransactionHistoryScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('Accomplished Goals & Tasks'),
                    leading: const Icon(CupertinoIcons.checkmark_seal_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const AccomplishedHistoryScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('Unfinished Goals'),
                    leading: const Icon(CupertinoIcons.flag_slash_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const UnfinishedGoalsScreen())),
                  ),
                  CupertinoListTile(
                    title: const Text('Unfinished Tasks'),
                    leading: const Icon(
                        CupertinoIcons.square_stack_3d_down_right_fill,
                        color: AppTheme.systemGray),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const UnfinishedTasksScreen())),
                  ),
                ],
              ),

              // Future Assets
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
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const WishlistScreen())),
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
