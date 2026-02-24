import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill.dart';
import '../models/session.dart';
import '../models/transaction.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../models/goal.dart';

class StorageService with ChangeNotifier {
  static const String _skillsKey = 'skills_data';
  static const String _sessionsKey = 'sessions_data';
  static const String _transactionsKey = 'transactions_data';
  static const String _habitsKey = 'habits_data';
  static const String _tasksKey = 'tasks_data';
  static const String _goalsKey = 'goals_data';
  static const String _wishlistKey = 'wishlist_data';
  static const String _activeSkillIdKey = 'active_skill_id';
  static const String _activeStartTimeKey = 'active_start_time';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Skills
  List<Skill> getSkills() {
    final String? data = _prefs.getString(_skillsKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Skill.fromJson(json)).toList();
  }

  Future<void> saveSkill(Skill skill) async {
    List<Skill> skills = getSkills();
    int index = skills.indexWhere((s) => s.id == skill.id);
    if (index >= 0) {
      skills[index] = skill;
    } else {
      skills.add(skill);
    }
    await _prefs.setString(
        _skillsKey, jsonEncode(skills.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteSkill(String id) async {
    List<Skill> skills = getSkills();
    skills.removeWhere((s) => s.id == id);
    await _prefs.setString(
        _skillsKey, jsonEncode(skills.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  // Sessions
  List<Session> getSessions() {
    final String? data = _prefs.getString(_sessionsKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Session.fromJson(json)).toList();
  }

  List<Session> getSessionsForSkill(String skillId) {
    return getSessions().where((s) => s.skillId == skillId).toList();
  }

  Future<void> saveSession(Session session) async {
    List<Session> sessions = getSessions();
    sessions.add(session);
    await _prefs.setString(
        _sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteSessionsForSkill(String skillId) async {
    List<Session> sessions = getSessions();
    sessions.removeWhere((s) => s.skillId == skillId);
    await _prefs.setString(
        _sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  // Transactions
  List<TransactionItem> getTransactions() {
    final String? data = _prefs.getString(_transactionsKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<void> saveTransaction(TransactionItem transaction) async {
    List<TransactionItem> txs = getTransactions();
    int index = txs.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      txs[index] = transaction;
    } else {
      txs.add(transaction);
    }
    await _prefs.setString(
        _transactionsKey, jsonEncode(txs.map((t) => t.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    List<TransactionItem> txsListOld = getTransactions();
    List<TransactionItem> txs = getTransactions();
    txs.removeWhere((t) => t.id == id);
    await _prefs.setString(
        _transactionsKey, jsonEncode(txs.map((t) => t.toJson()).toList()));

    // Reverse Loop: if transaction has linkedWishlistId, un-buy it
    final txToDelete = txsListOld.firstWhere((t) => t.id == id,
        orElse: () => TransactionItem(
            id: '',
            title: '',
            amount: 0,
            date: DateTime.now(),
            type: TransactionType.expense));
    if (txToDelete.linkedWishlistId != null) {
      final wishlistRaw = getWishlistRaw();
      for (var i = 0; i < wishlistRaw.length; i++) {
        if (wishlistRaw[i]['id'] == txToDelete.linkedWishlistId) {
          wishlistRaw[i]['isBought'] = false;
        }
      }
      await _prefs.setString(_wishlistKey, jsonEncode(wishlistRaw));
    }

    notifyListeners();
  }

  // Habits
  List<Habit> getHabits() {
    final String? data = _prefs.getString(_habitsKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Habit.fromJson(json)).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    List<Habit> habits = getHabits();
    int index = habits.indexWhere((h) => h.id == habit.id);
    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }
    await _prefs.setString(
        _habitsKey, jsonEncode(habits.map((h) => h.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveAllHabits(List<Habit> habits) async {
    await _prefs.setString(
        _habitsKey, jsonEncode(habits.map((h) => h.toJson()).toList()));
    notifyListeners();
  }

  // Tasks
  List<TaskItem> getTasks() {
    final String? data = _prefs.getString(_tasksKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => TaskItem.fromJson(json)).toList();
  }

  Future<void> saveTask(TaskItem task) async {
    List<TaskItem> tasks = getTasks();
    int index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await _prefs.setString(
        _tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveAllTasks(List<TaskItem> tasks) async {
    await _prefs.setString(
        _tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
    notifyListeners();
  }

  // Goals
  List<Goal> getGoals() {
    final String? data = _prefs.getString(_goalsKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Goal.fromJson(json)).toList();
  }

  Future<void> saveGoal(Goal goal) async {
    List<Goal> goals = getGoals();
    int index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    await _prefs.setString(
        _goalsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveAllGoals(List<Goal> goals) async {
    await _prefs.setString(
        _goalsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
    notifyListeners();
  }

  // Wishlist
  List<dynamic> getWishlistRaw() {
    final String? data = _prefs.getString(_wishlistKey);
    if (data == null) return [];
    return jsonDecode(data);
  }

  Future<void> saveWishlistRaw(List<dynamic> items) async {
    await _prefs.setString(_wishlistKey, jsonEncode(items));
    notifyListeners();
  }

  // Timer State
  String? getActiveSkillId() {
    return _prefs.getString(_activeSkillIdKey);
  }

  DateTime? getActiveStartTime() {
    final String? data = _prefs.getString(_activeStartTimeKey);
    if (data == null) return null;
    return DateTime.parse(data);
  }

  Future<void> saveActiveTimerState(String skillId, DateTime startTime) async {
    await _prefs.setString(_activeSkillIdKey, skillId);
    await _prefs.setString(_activeStartTimeKey, startTime.toIso8601String());
    notifyListeners();
  }

  Future<void> clearActiveTimerState() async {
    await _prefs.remove(_activeSkillIdKey);
    await _prefs.remove(_activeStartTimeKey);
    notifyListeners();
  }
}
