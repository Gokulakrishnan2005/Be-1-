import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/goal.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class AddGoalModal extends StatefulWidget {
  final VoidCallback onAdded;

  const AddGoalModal({super.key, required this.onAdded});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  GoalType _selectedType = GoalType.weekly;

  void _saveGoal() async {
    final title = _titleController.text.trim();
    final targetStr = _targetController.text.trim();
    final unit = _unitController.text.trim();

    if (title.isNotEmpty && targetStr.isNotEmpty && unit.isNotEmpty) {
      final targetVal = double.tryParse(targetStr);
      if (targetVal == null) return;

      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final newGoal = Goal(
        id: const Uuid().v4(),
        title: title,
        targetValue: targetVal,
        unit: unit,
        type: _selectedType,
      );

      await storage.saveGoal(newGoal);
      widget.onAdded();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Goal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoSlidingSegmentedControl<GoalType>(
            groupValue: _selectedType,
            children: const {
              GoalType.weekly: Text('Weekly'),
              GoalType.monthly: Text('Monthly'),
              GoalType.yearly: Text('Yearly'),
            },
            onValueChanged: (val) {
              if (val != null) {
                HapticWrapper.light();
                setState(() => _selectedType = val);
              }
            },
          ),
          const SizedBox(height: 24),
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Goal Title (e.g. Run 50km)',
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CupertinoTextField(
                  controller: _targetController,
                  placeholder: 'Target (e.g. 50)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pureCeramicWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: CupertinoTextField(
                  controller: _unitController,
                  placeholder: 'Unit (km)',
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.pureCeramicWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.systemBlack,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveGoal,
              child: const Text('Add Goal',
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
