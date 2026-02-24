import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class AddHabitModal extends StatefulWidget {
  final VoidCallback onAdded;

  const AddHabitModal({super.key, required this.onAdded});

  @override
  State<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  final TextEditingController _nameController = TextEditingController();

  void _saveHabit() async {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final newHabit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        iconCode: CupertinoIcons.flame_fill.codePoint,
      );

      await storage.saveHabit(newHabit);
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
            'New Daily Action',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoTextField(
            controller: _nameController,
            placeholder: 'Habit Name (e.g. Meditate for 10m)',
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.systemBlack,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveHabit,
              child: const Text('Add Action',
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
