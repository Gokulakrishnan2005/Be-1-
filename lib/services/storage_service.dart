import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill.dart';
import '../models/session.dart';
import '../models/transaction.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../models/goal.dart';
import '../models/credential.dart';
import '../models/journal_entry.dart';
import '../models/place.dart';

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
  static const String _strictModeKey = 'strict_mode';
  static const String _genesisCompleteKey = 'genesis_complete';
  static const String _userNameKey = 'user_name';
  static const String _userDobKey = 'user_dob';
  static const String _userGenderKey = 'user_gender';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _vaultPinKey = 'vault_pin';
  static const String _credentialsKey = 'credentials_data';
  static const String _journalKey = 'journal_data';
  static const String _placesKey = 'places_data';

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
    var skills = jsonList.map((json) => Skill.fromJson(json)).toList();
    skills.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return skills;
  }

  Future<void> updateSkillOrder(List<Skill> orderedSkills) async {
    // Re-assign orderIndex based on the new list position
    for (int i = 0; i < orderedSkills.length; i++) {
      orderedSkills[i] = Skill(
        id: orderedSkills[i].id,
        name: orderedSkills[i].name,
        iconName: orderedSkills[i].iconName,
        targetHours: orderedSkills[i].targetHours,
        category: orderedSkills[i].category,
        orderIndex: i, // Ensure deterministic integer
      );
    }
    await _prefs.setString(
        _skillsKey, jsonEncode(orderedSkills.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveSkill(Skill skill) async {
    List<Skill> skills = getSkills();
    int index = skills.indexWhere((s) => s.id == skill.id);
    if (index >= 0) {
      skills[index] = skill;
    } else {
      // New skills go to the end
      final newSkillWithOrder = Skill(
        id: skill.id,
        name: skill.name,
        iconName: skill.iconName,
        targetHours: skill.targetHours,
        category: skill.category,
        orderIndex: skills.length,
      );
      skills.add(newSkillWithOrder);
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

  Future<void> deleteSession(String sessionId) async {
    List<Session> sessions = getSessions();
    sessions.removeWhere((s) => s.id == sessionId);
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

  Future<void> archiveHabit(String id) async {
    List<Habit> habits = getHabits();
    final index = habits.indexWhere((h) => h.id == id);
    if (index < 0) return;

    final h = habits[index];
    habits[index] = Habit(
      id: h.id,
      name: h.name,
      iconCode: h.iconCode,
      isCompleted: h.isCompleted,
      streak: h.streak,
      createdAt: h.createdAt,
      isArchived: true,
      archivedAt: DateTime.now(),
      completedDates: h.completedDates,
    );
    await _prefs.setString(
        _habitsKey, jsonEncode(habits.map((h) => h.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteHabitPermanently(String id) async {
    List<Habit> habits = getHabits();
    habits.removeWhere((h) => h.id == id);
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

  // Strict 24/7 Mode
  bool getStrictMode() {
    return _prefs.getBool(_strictModeKey) ?? true;
  }

  Future<void> setStrictMode(bool value) async {
    await _prefs.setBool(_strictModeKey, value);
    notifyListeners();
  }

  // Genesis State
  bool isGenesisComplete() {
    return _prefs.getBool(_genesisCompleteKey) ?? false;
  }

  Future<void> setGenesisComplete() async {
    await _prefs.setBool(_genesisCompleteKey, true);
  }

  // ─── ONBOARDING / IDENTITY ──────────────────────────────────
  String getUserName() => _prefs.getString(_userNameKey) ?? '';
  Future<void> setUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
    notifyListeners();
  }

  String? getUserDob() => _prefs.getString(_userDobKey);
  Future<void> setUserDob(DateTime dob) async {
    await _prefs.setString(_userDobKey, dob.toIso8601String());
    notifyListeners();
  }

  String getUserGender() => _prefs.getString(_userGenderKey) ?? '';
  Future<void> setUserGender(String gender) async {
    await _prefs.setString(_userGenderKey, gender);
  }

  bool isOnboardingComplete() =>
      _prefs.getBool(_onboardingCompleteKey) ?? false;
  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingCompleteKey, true);
  }

  // ─── VAULT ───────────────────────────────────────────────────
  String? getVaultPin() => _prefs.getString(_vaultPinKey);
  Future<void> setVaultPin(String pin) async {
    await _prefs.setString(_vaultPinKey, pin);
  }

  List<Credential> getCredentials() {
    final raw = _prefs.getString(_credentialsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Credential.fromJson(e))
        .toList();
  }

  Future<void> saveCredential(Credential cred) async {
    var list = getCredentials();
    final idx = list.indexWhere((c) => c.id == cred.id);
    if (idx >= 0) {
      list[idx] = cred;
    } else {
      list.add(cred);
    }
    await _prefs.setString(
        _credentialsKey, jsonEncode(list.map((c) => c.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteCredential(String id) async {
    var list = getCredentials();
    list.removeWhere((c) => c.id == id);
    await _prefs.setString(
        _credentialsKey, jsonEncode(list.map((c) => c.toJson()).toList()));
    notifyListeners();
  }

  // ─── JOURNAL ─────────────────────────────────────────────────
  List<JournalEntry> getJournalEntries() {
    final raw = _prefs.getString(_journalKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => JournalEntry.fromJson(e))
        .toList();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    var list = getJournalEntries();
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    await _prefs.setString(
        _journalKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deleteJournalEntry(String id) async {
    var list = getJournalEntries();
    list.removeWhere((e) => e.id == id);
    await _prefs.setString(
        _journalKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  // ─── PLACES (Experience Board) ───────────────────────────────
  List<Place> getPlaces() {
    final raw = _prefs.getString(_placesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Place.fromJson(e)).toList();
  }

  Future<void> savePlace(Place place) async {
    var list = getPlaces();
    final idx = list.indexWhere((p) => p.id == place.id);
    if (idx >= 0) {
      list[idx] = place;
    } else {
      list.add(place);
    }
    await _prefs.setString(
        _placesKey, jsonEncode(list.map((p) => p.toJson()).toList()));
    notifyListeners();
  }

  Future<void> deletePlace(String id) async {
    var list = getPlaces();
    list.removeWhere((p) => p.id == id);
    await _prefs.setString(
        _placesKey, jsonEncode(list.map((p) => p.toJson()).toList()));
    notifyListeners();
  }
}
