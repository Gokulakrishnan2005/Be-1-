import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../widgets/habit_heatmap_card.dart';

class HabitAnalyticsScreen extends StatefulWidget {
  const HabitAnalyticsScreen({super.key});

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  int _selectedSegment = 0; // 0 = Active, 1 = Archived

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final allHabits = storage.getHabits();

    final activeHabits = allHabits.where((h) => !h.isArchived).toList();
    final archivedHabits = allHabits.where((h) => h.isArchived).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.systemGray6,
        border: null,
        middle: Text('Habit Analytics'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Active (${activeHabits.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Graveyard (${archivedHabits.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    setState(() => _selectedSegment = value ?? 0);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _selectedSegment == 0
                  ? _buildActiveList(activeHabits)
                  : _buildArchivedList(archivedHabits, storage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(List activeHabits) {
    if (activeHabits.isEmpty) {
      return const Center(
        child: Text(
          'No active habits.\nAdd habits in Tab 3.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.systemGray, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: activeHabits.length,
      itemBuilder: (context, index) {
        return HabitHeatmapCard(habit: activeHabits[index]);
      },
    );
  }

  Widget _buildArchivedList(List archivedHabits, StorageService storage) {
    if (archivedHabits.isEmpty) {
      return const Center(
        child: Text(
          'The graveyard is empty.\nArchived habits will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.systemGray, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: archivedHabits.length,
      itemBuilder: (context, index) {
        final habit = archivedHabits[index];
        return HabitHeatmapCard(
          habit: habit,
          endDate: habit.archivedAt,
          onDelete: () async {
            await storage.deleteHabitPermanently(habit.id);
          },
        );
      },
    );
  }
}
