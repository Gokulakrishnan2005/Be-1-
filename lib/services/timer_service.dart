import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart'; // We should probably add this to pubspec, but will mock uuid generation for now.
import '../models/session.dart';
import '../models/skill.dart';
import 'storage_service.dart';
import 'notification_service.dart';

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
  void switchTimer(String skillId, StorageService storageService) {
    if (_activeSkillId == skillId) {
      // Already active. No pausing allowed in the continuous life-logger.
      return;
    }

    HapticFeedback.heavyImpact();

    // If a different timer is active, pause it before starting the new one.
    if (_activeSkillId != null) {
      _pauseActiveTimer(storageService);
    }
    _startTimer(skillId, storageService);
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
      id: DateTime.now().millisecondsSinceEpoch.toString() + "_retro",
      skillId: entropySkillId,
      startTime: now.subtract(wastedDuration),
      endTime: now,
      durationSeconds: wastedDuration.inSeconds,
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
          NotificationService().showRegretNotification();
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
