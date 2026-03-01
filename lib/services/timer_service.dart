import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
// We should probably add this to pubspec, but will mock uuid generation for now.
import '../models/session.dart';
import '../models/skill.dart';
import 'storage_service.dart';

class TimerService extends ChangeNotifier {
  String? _activeSkillId;
  DateTime? _activeStartTime;
  Timer? _ticker;

  final StreamController<void> _genesisEventController =
      StreamController<void>.broadcast();
  Stream<void> get genesisEventStream => _genesisEventController.stream;

  String? get activeSkillId => _activeSkillId;
  bool get isTimerActive => _activeSkillId != null;
  DateTime? get activeStartTime => _activeStartTime;

  Duration get currentDuration {
    if (_activeStartTime == null) return Duration.zero;
    return DateTime.now().difference(_activeStartTime!);
  }

  // Starts or switches the global timer
  void switchTimer(String skillId, StorageService storageService,
      {bool strictMode = true}) {
    if (_activeSkillId == skillId) {
      // If strict mode is OFF, allow pausing the active timer
      if (!strictMode) {
        pauseTimer(storageService);
      }
      // If strict mode is ON, no-op (continuous life-logger)
      return;
    }

    HapticFeedback.heavyImpact();

    // If a different timer is active, pause it before starting the new one.
    if (_activeSkillId != null) {
      _pauseActiveTimer(storageService);
    }
    _startTimer(skillId, storageService);
  }

  /// Publicly accessible pause: fully stops the active timer and saves session.
  void pauseTimer(StorageService storageService) {
    if (_activeSkillId == null || _activeStartTime == null) return;
    HapticFeedback.heavyImpact();
    _pauseActiveTimer(storageService);
  }

  void splitAndSwitchTimer(String oldSkillId, Duration oldSkillDuration,
      String newSkillId, StorageService storageService) {
    if (_activeSkillId != oldSkillId || _activeStartTime == null) return;

    final oldEndTime = _activeStartTime!.add(oldSkillDuration);

    // Check for Genesis Event
    final existingSessions = storageService.getSessionsForSkill(oldSkillId);
    if (existingSessions.isEmpty) {
      _genesisEventController.add(null);
    }

    // Save old session
    final oldSession = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      skillId: oldSkillId,
      startTime: _activeStartTime!,
      endTime: oldEndTime,
      durationSeconds: oldSkillDuration.inSeconds,
    );
    storageService.saveSession(oldSession);

    // Start new timer backdated
    _activeSkillId = newSkillId;
    _activeStartTime = oldEndTime;
    storageService.saveActiveTimerState(newSkillId, _activeStartTime!);

    if (_ticker == null || !_ticker!.isActive) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void auditAndSwitchTimer(
      String oldSkillId,
      Duration totalDuration,
      Duration deepWorkDuration,
      String? wasteSkillId,
      String newSkillId,
      StorageService storageService) {
    if (_activeSkillId != oldSkillId || _activeStartTime == null) return;

    final oldEndTime = _activeStartTime!.add(totalDuration);
    final wasteDuration = totalDuration - deepWorkDuration;

    // Check for Genesis Event (Growth)
    final existingSessions = storageService.getSessionsForSkill(oldSkillId);
    if (existingSessions.isEmpty) {
      _genesisEventController.add(null);
    }

    // 1. Save Deep Work Session
    if (deepWorkDuration.inSeconds > 0) {
      final deepWorkSession = Session(
        id: "${DateTime.now().millisecondsSinceEpoch}_dw",
        skillId: oldSkillId,
        startTime: _activeStartTime!,
        endTime: _activeStartTime!.add(deepWorkDuration),
        durationSeconds: deepWorkDuration.inSeconds,
        isEdited: true, // Split operation implies retroactive editing
      );
      storageService.saveSession(deepWorkSession);
    }

    // 2. Save Waste Session (if applicable)
    if (wasteDuration.inSeconds > 0 && wasteSkillId != null) {
      final existingWasteSessions =
          storageService.getSessionsForSkill(wasteSkillId);
      if (existingWasteSessions.isEmpty) {
        _genesisEventController.add(null);
      }

      final wasteSession = Session(
        id: "${DateTime.now().millisecondsSinceEpoch}_waste",
        skillId: wasteSkillId,
        startTime: _activeStartTime!.add(deepWorkDuration),
        endTime: oldEndTime,
        durationSeconds: wasteDuration.inSeconds,
        isEdited: true, // Split operation implies retroactive editing
      );
      storageService.saveSession(wasteSession);
    }

    // 3. Start New Timer
    _activeSkillId = newSkillId;
    _activeStartTime = oldEndTime;
    storageService.saveActiveTimerState(newSkillId, _activeStartTime!);

    _startTicker(storageService);

    notifyListeners();
  }

  /// Multi-split audit: Replace the current active session with N separate sessions.
  /// Called from the MultiSplitAuditModal context menu "Audit Session".
  void multiSplitAudit(
    String originalSkillId,
    List<MapEntry<String, int>> splits,
    StorageService storageService,
  ) {
    if (_activeSkillId != originalSkillId || _activeStartTime == null) return;

    HapticFeedback.heavyImpact();
    DateTime cursor = _activeStartTime!;
    final now = DateTime.now();

    for (int i = 0; i < splits.length; i++) {
      final skillId = splits[i].key;
      final durSeconds = splits[i].value;
      if (durSeconds <= 0) continue;

      final endTime = cursor.add(Duration(seconds: durSeconds));
      final existing = storageService.getSessionsForSkill(skillId);
      if (existing.isEmpty) _genesisEventController.add(null);

      final session = Session(
        id: "${DateTime.now().millisecondsSinceEpoch}_split$i",
        skillId: skillId,
        startTime: cursor,
        endTime: endTime,
        durationSeconds: durSeconds,
        isEdited: true,
      );
      storageService.saveSession(session);
      cursor = endTime;
    }

    _activeStartTime = now;
    storageService.saveActiveTimerState(_activeSkillId!, _activeStartTime!);
    notifyListeners();
  }

  /// Multi-split audit + SWITCH: Saves the splits for the old timer,
  /// then starts a new timer for [newSkillId].
  /// Used by the Switch Interrupt (> 30 min threshold).
  void multiSplitAuditAndSwitch(
    String oldSkillId,
    List<MapEntry<String, int>> splits,
    String newSkillId,
    StorageService storageService,
  ) {
    if (_activeSkillId != oldSkillId || _activeStartTime == null) return;

    HapticFeedback.heavyImpact();
    DateTime cursor = _activeStartTime!;

    // Save all split sessions
    for (int i = 0; i < splits.length; i++) {
      final skillId = splits[i].key;
      final durSeconds = splits[i].value;
      if (durSeconds <= 0) continue;

      final endTime = cursor.add(Duration(seconds: durSeconds));
      final existing = storageService.getSessionsForSkill(skillId);
      if (existing.isEmpty) _genesisEventController.add(null);

      final session = Session(
        id: "${DateTime.now().millisecondsSinceEpoch}_split$i",
        skillId: skillId,
        startTime: cursor,
        endTime: endTime,
        durationSeconds: durSeconds,
        isEdited: true,
      );
      storageService.saveSession(session);
      cursor = endTime;
    }

    // Start new timer from cursor position
    _activeSkillId = newSkillId;
    _activeStartTime = cursor;
    storageService.saveActiveTimerState(newSkillId, _activeStartTime!);

    _startTicker(storageService);
    notifyListeners();
  }

  /// Audit a previously completed session (from "Audit Last Session" menu).
  /// Deletes the original session and replaces it with N split sessions.
  void auditLastSession(
    String skillId,
    String originalSessionId,
    List<MapEntry<String, int>> splits,
    StorageService storageService,
  ) {
    HapticFeedback.heavyImpact();

    // Find the original session to get its start time
    final sessions = storageService.getSessionsForSkill(skillId);
    final original = sessions.firstWhere(
      (s) => s.id == originalSessionId,
      orElse: () => Session(
        id: '',
        skillId: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        durationSeconds: 0,
      ),
    );
    if (original.id.isEmpty) return;

    // Delete the original session
    storageService.deleteSession(originalSessionId);

    // Create replacement sessions
    DateTime cursor = original.startTime;
    for (int i = 0; i < splits.length; i++) {
      final splitSkillId = splits[i].key;
      final durSeconds = splits[i].value;
      if (durSeconds <= 0) continue;

      final endTime = cursor.add(Duration(seconds: durSeconds));
      final existing = storageService.getSessionsForSkill(splitSkillId);
      if (existing.isEmpty) _genesisEventController.add(null);

      final session = Session(
        id: "${DateTime.now().millisecondsSinceEpoch}_audit$i",
        skillId: splitSkillId,
        startTime: cursor,
        endTime: endTime,
        durationSeconds: durSeconds,
        isEdited: true,
      );
      storageService.saveSession(session);
      cursor = endTime;
    }

    notifyListeners();
  }

  void retroactiveLog(String entropySkillId, Duration wastedDuration,
      StorageService storageService) {
    HapticFeedback.heavyImpact();
    final now = DateTime.now();

    // 1. Inject the wasted time right up to now
    final existingSessions = storageService.getSessionsForSkill(entropySkillId);
    if (existingSessions.isEmpty) {
      _genesisEventController.add(null);
    }

    final entropySession = Session(
      id: "${DateTime.now().millisecondsSinceEpoch}_retro",
      skillId: entropySkillId,
      startTime: now.subtract(wastedDuration),
      endTime: now,
      durationSeconds: wastedDuration.inSeconds,
      isEdited: true, // Explicitly backlogged
    );
    storageService.saveSession(entropySession);

    // 2. Adjust current active timer if present
    if (_activeSkillId != null && _activeStartTime != null) {
      // If the current timer hasn't been running for the full wasted duration,
      // pushing it forward beyond now would create a negative block.
      // To keep it simple, we just set the active start time to `now`
      // resetting their currently observed focus block.
      _activeStartTime = now;
      storageService.saveActiveTimerState(_activeSkillId!, _activeStartTime!);
    }

    notifyListeners();
  }

  void deleteLastRetroactiveLog(
      String entropySkillId, StorageService storageService) {
    HapticFeedback.heavyImpact();

    final sessions = storageService.getSessionsForSkill(entropySkillId);

    // Find sessions ending with `_retro`
    final retroSessions =
        sessions.where((s) => s.id.endsWith('_retro')).toList();
    if (retroSessions.isEmpty) return;

    // Sort to find the most recent one (start time descending)
    retroSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    final lastRetro = retroSessions.first;

    storageService.deleteSession(lastRetro.id);
    notifyListeners();
  }

  void _startTimer(String skillId, StorageService storageService) {
    _activeSkillId = skillId;
    _activeStartTime = DateTime.now();

    storageService.saveActiveTimerState(skillId, _activeStartTime!);

    _startTicker(storageService);

    notifyListeners();
  }

  void _startTicker(StorageService storageService) {
    if (_ticker != null && _ticker!.isActive) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSkillId != null && currentDuration.inSeconds == 7200) {
        final skill = storageService.getSkills().firstWhere(
            (s) => s.id == _activeSkillId,
            orElse: () =>
                Skill(id: '', name: '', iconName: '', targetHours: 0));
        if (skill.category == 'ENTROPY') {
          // Notifications temporarily disabled to prevent Android launch crashes
        }
      }
      notifyListeners();
    });
  }

  void _pauseActiveTimer(StorageService storageService) {
    if (_activeSkillId == null || _activeStartTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(_activeStartTime!);

    // Check for Genesis Event (first session ever for this skill)
    final existingSessions =
        storageService.getSessionsForSkill(_activeSkillId!);
    if (existingSessions.isEmpty) {
      _genesisEventController.add(null);
    }

    // Save session
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // simple ID
      skillId: _activeSkillId!,
      startTime: _activeStartTime!,
      endTime: now,
      durationSeconds: duration.inSeconds,
    );

    storageService.saveSession(session);
    storageService.clearActiveTimerState();

    _activeSkillId = null;
    _activeStartTime = null;
    _ticker?.cancel();
    _ticker = null;

    notifyListeners();
  }

  void restoreState(StorageService storageService) {
    _activeSkillId = storageService.getActiveSkillId();
    _activeStartTime = storageService.getActiveStartTime();

    if (_activeSkillId != null && _activeStartTime != null) {
      _startTicker(storageService);
      notifyListeners();
    } else {
      _activeSkillId = null;
      _activeStartTime = null;
    }
  }

  @override
  void dispose() {
    _genesisEventController.close();
    super.dispose();
  }
}
