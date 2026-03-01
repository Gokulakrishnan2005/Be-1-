import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/task_item.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class AddTaskModal extends StatefulWidget {
  final VoidCallback onAdded;

  const AddTaskModal({super.key, required this.onAdded});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final TextEditingController _titleController = TextEditingController();

  void _saveTask() async {
    final title = _titleController.text.trim();

    if (title.isNotEmpty) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final newTask = TaskItem(
        id: const Uuid().v4(),
        title: title,
      );

      await storage.saveTask(newTask);
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
            'New Task (One-off)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Task Title (e.g. Call Bank)',
            style: const TextStyle(color: AppTheme.systemBlack),
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
              onPressed: _saveTask,
              child: const Text('Add Task',
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
