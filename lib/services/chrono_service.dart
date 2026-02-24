import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../models/goal.dart';

class ChronoService {
  static const String _lastSweepDateKey = 'last_chrono_sweep_date';

  static Future<void> performBoundarySweep(StorageService storage) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSweepStr = prefs.getString(_lastSweepDateKey);
    final DateTime now = DateTime.now();

    // Always check for goal expirations every time app mounts.
    _sweepGoals(storage, now);

    // Provide strict daily sweep bounding.
    if (lastSweepStr != null) {
      final DateTime lastSweep = DateTime.parse(lastSweepStr);
      // Diffing using YYYY-MM-DD
      if (!_isSameDay(lastSweep, now)) {
        _sweepDailyTasksAndHabits(storage, now);
      }
    } else {
      // First time running, just save today's date
      prefs.setString(_lastSweepDateKey, now.toIso8601String());
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static void _sweepGoals(StorageService storage, DateTime now) {
    List<Goal> goals = storage.getGoals();
    bool needsSave = false;

    // We do NOT purge Goals from the list directly;
    // We strictly transition them based on completion so they render appropriately inside Profile Archive.
    for (int i = 0; i < goals.length; i++) {
      if (goals[i].status == GoalStatus.active &&
          now.isAfter(goals[i].expiresAt)) {
        GoalStatus finalStatus = goals[i].currentValue >= goals[i].targetValue
            ? GoalStatus.success
            : GoalStatus.failed;
        goals[i] = goals[i].copyWith(newStatus: finalStatus);
        needsSave = true;
      }
    }

    if (needsSave) {
      storage.saveAllGoals(goals);
    }
  }

  static Future<void> _sweepDailyTasksAndHabits(
      StorageService storage, DateTime now) async {
    // 1. Archive tasks created on preceding days instead of purging
    List<TaskItem> tasks = storage.getTasks();
    bool needsTaskSave = false;
    for (int i = 0; i < tasks.length; i++) {
      if (!_isSameDay(tasks[i].createdAt, now) && !tasks[i].isArchived) {
        tasks[i] = TaskItem(
          id: tasks[i].id,
          title: tasks[i].title,
          isCompleted: tasks[i].isCompleted,
          isArchived: true,
          snoozeCount: tasks[i].snoozeCount,
          createdAt: tasks[i].createdAt,
          completedAt: tasks[i].completedAt,
        );
        needsTaskSave = true;
      }
    }
    if (needsTaskSave) storage.saveAllTasks(tasks);

    // 2. Reset Habits & Compute Streaks
    List<Habit> habits = storage.getHabits();
    bool needsHabitSave = false;

    for (int i = 0; i < habits.length; i++) {
      if (habits[i].isCompleted) {
        // Technically missed yesterday if it's not completed by today's sweep,
        // Wait, if it IS completed, it means they did it yesterday. So Streak is maintained. Reset completed flag.
        habits[i] = Habit(
          id: habits[i].id,
          name: habits[i].name,
          iconCode: habits[i].iconCode,
          isCompleted: false, // Reset!
          streak: habits[i].streak + 1, // Passed!
          createdAt: habits[i].createdAt,
        );
      } else {
        // Did NOT complete it. Streak broken.
        habits[i] = Habit(
          id: habits[i].id,
          name: habits[i].name,
          iconCode: habits[i].iconCode,
          isCompleted: false,
          streak: 0, // Failed!
          createdAt: habits[i].createdAt,
        );
      }
      needsHabitSave = true;
    }

    if (needsHabitSave) {
      storage.saveAllHabits(habits);
    }

    // Update sweep date
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_lastSweepDateKey, now.toIso8601String());
  }
}
