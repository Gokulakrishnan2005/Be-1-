import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../../models/skill.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class GrowthInterrogationModal extends StatefulWidget {
  final Duration totalDuration;
  final List<Skill> maintenanceAndEntropySkills;
  final Function(Duration deepWorkDuration, String? wasteSkillId) onConfirm;

  const GrowthInterrogationModal({
    super.key,
    required this.totalDuration,
    required this.maintenanceAndEntropySkills,
    required this.onConfirm,
  });

  @override
  State<GrowthInterrogationModal> createState() =>
      _GrowthInterrogationModalState();
}

class _GrowthInterrogationModalState extends State<GrowthInterrogationModal> {
  late double _sliderValue;
  String? _selectedWasteSkillId;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.totalDuration.inMinutes.toDouble();
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
    final deepWorkMins = _sliderValue.toInt();
    final wasteMins = totalMins - deepWorkMins;
    final hasWaste = wasteMins > 0;

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
          const Text(
            'Time Audit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Timer ran for ${_formatDuration(totalMins)}. How much of this was truly deep work?',
            style: const TextStyle(color: AppTheme.systemGray, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              _formatDuration(deepWorkMins),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppTheme.stateGrowth,
                letterSpacing: -2,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _sliderValue,
              min: 0,
              max: math.max(1.0, totalMins.toDouble()),
              activeColor: AppTheme.stateGrowth,
              thumbColor: AppTheme.pureCeramicWhite,
              onChanged: (val) {
                setState(() => _sliderValue = val);
                HapticWrapper.light();
              },
            ),
          ),
          const SizedBox(height: 24),
          if (hasWaste && widget.maintenanceAndEntropySkills.isNotEmpty) ...[
            const Text(
              'Where did the rest of the time go?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.systemBlack,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.pureCeramicWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (int index) {
                  HapticWrapper.light();
                  setState(() {
                    _selectedWasteSkillId =
                        widget.maintenanceAndEntropySkills[index].id;
                  });
                },
                children: widget.maintenanceAndEntropySkills.map((skill) {
                  return Center(
                    child: Text(
                      skill.name,
                      style: TextStyle(
                        color: skill.category == 'ENTROPY'
                            ? AppTheme.stateEntropy
                            : AppTheme.stateMaintenance,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.systemBlack,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                // If there's waste but they didn't touch the picker, default to first item
                String? finalWasteId = _selectedWasteSkillId;
                if (hasWaste &&
                    finalWasteId == null &&
                    widget.maintenanceAndEntropySkills.isNotEmpty) {
                  finalWasteId = widget.maintenanceAndEntropySkills.first.id;
                }

                HapticWrapper.heavy();
                widget.onConfirm(Duration(minutes: deepWorkMins), finalWasteId);
                Navigator.pop(context);
              },
              child: const Text('Confirm & Switch',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureCeramicWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
