import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/task_item.dart';
import '../models/goal.dart';
import '../services/storage_service.dart';
import '../services/chrono_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_item.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/goal_card.dart';

class OrganizerScreen extends StatefulWidget {
  const OrganizerScreen({super.key});

  @override
  State<OrganizerScreen> createState() => OrganizerScreenState();
}

class OrganizerScreenState extends State<OrganizerScreen> {
  late final StorageService _storageService;
  List<Habit> _habits = [];
  List<TaskItem> _tasks = [];
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _loadData();
  }

  Future<void> _loadData() async {
    // Perform boundary sweep implicitly when screen mounts
    await ChronoService.performBoundarySweep(_storageService);

    if (mounted) {
      setState(() {
        _habits = _storageService.getHabits();
        _tasks =
            _storageService.getTasks().where((t) => !t.isArchived).toList();
        _goals = _storageService
            .getGoals()
            .where((g) => g.status == GoalStatus.active)
            .toList();
      });
    }
  }

  void refresh() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final weeklyGoals = _goals.where((g) => g.type == GoalType.weekly).toList();
    final monthlyGoals =
        _goals.where((g) => g.type == GoalType.monthly).toList();
    final yearlyGoals = _goals.where((g) => g.type == GoalType.yearly).toList();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme
          .pureCeramicWhite, // Minimalist stark background for clipboard
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                    left: 24.0, right: 24.0, top: 40.0, bottom: 24.0),
                child: Text(
                  'Daily Action',
                  style: TextStyle(
                    color: AppTheme.systemBlack,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),

              // Goals Views
              ..._buildGoalSection('Weekly Goals', weeklyGoals),
              ..._buildGoalSection('Monthly Goals', monthlyGoals),
              ..._buildGoalSection('Yearly Goals', yearlyGoals),

              // Checklists
              if (_tasks.isNotEmpty || _habits.isNotEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Text(
                    'Today',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5),
                  ),
                ),

              if (_tasks.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return TaskItemWidget(
                      task: task,
                      onToggle: refresh,
                      onDismissed: () {
                        setState(() {
                          _tasks.removeWhere((t) => t.id == task.id);
                        });
                      },
                    );
                  },
                ),

              if (_habits.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    return HabitItem(
                      habit: _habits[index],
                      onToggle: refresh,
                    );
                  },
                ),

              // Empty State
              if (_habits.isEmpty && _tasks.isEmpty && _goals.isEmpty)
                Container(
                  padding: const EdgeInsets.only(top: 100),
                  alignment: Alignment.center,
                  child: const Text(
                    'Your clipboard is empty.\nTap + to add an action or goal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.systemGray),
                  ),
                ),

              // Bottom padding for nav bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGoalSection(String title, List<Goal> items) {
    if (items.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GoalCard(
              goal: items[index],
              onUpdated: refresh,
            ),
          );
        },
      ),
    ];
  }
}
