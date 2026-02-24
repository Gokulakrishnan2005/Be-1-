import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class TimeSplitterModal extends StatefulWidget {
  final String oldSkillName;
  final String newSkillName;
  final Duration totalDuration;
  final Function(Duration oldSkillDuration, Duration newSkillDuration) onSplit;
  final VoidCallback onMachine;

  const TimeSplitterModal({
    super.key,
    required this.oldSkillName,
    required this.newSkillName,
    required this.totalDuration,
    required this.onSplit,
    required this.onMachine,
  });

  @override
  State<TimeSplitterModal> createState() => _TimeSplitterModalState();
}

class _TimeSplitterModalState extends State<TimeSplitterModal> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    // Default to giving half to the new skill, half to old
    _sliderValue = widget.totalDuration.inMinutes / 2;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final totalMins = widget.totalDuration.inMinutes;
    final oldMins = totalMins - _sliderValue.toInt();
    final newMins = _sliderValue.toInt();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.systemGray6,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You tracked ${widget.oldSkillName} for ${_formatDuration(totalMins)}.',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Is this accurate? Or did you forget to switch tasks?',
            style: TextStyle(color: AppTheme.systemGray, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.oldSkillName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.systemGray)),
                  const SizedBox(height: 4),
                  Text(_formatDuration(oldMins),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.focusBlue)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.newSkillName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.systemGray)),
                  const SizedBox(height: 4),
                  Text(_formatDuration(newMins),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.stateGrowth)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _sliderValue,
              min: 0,
              max: totalMins.toDouble(),
              activeColor: AppTheme.stateGrowth,
              thumbColor: AppTheme.pureCeramicWhite,
              onChanged: (val) {
                setState(() => _sliderValue = val);
                HapticWrapper.light();
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.focusBlue,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticWrapper.medium();
                widget.onSplit(
                    Duration(minutes: oldMins), Duration(minutes: newMins));
                Navigator.pop(context);
              },
              child: const Text('Split Time',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticWrapper.medium();
                widget.onMachine();
                Navigator.pop(context);
              },
              child: const Text('Yes, I\'m a Machine',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.systemBlack)),
            ),
          ),
        ],
      ),
    );
  }
}
