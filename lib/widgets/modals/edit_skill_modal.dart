import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/skill.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class EditSkillModal extends StatefulWidget {
  final Skill skill;
  final VoidCallback onEdited;

  const EditSkillModal(
      {super.key, required this.skill, required this.onEdited});

  @override
  State<EditSkillModal> createState() => _EditSkillModalState();
}

class _EditSkillModalState extends State<EditSkillModal> {
  late TextEditingController _nameController;
  late String _selectedIcon;

  final List<String> _icons = ['book', 'code', 'gym', 'guitar'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill.name);
    _selectedIcon = widget.skill.iconName;
    // ensure the icon falls back to 'book' if not found in array (though custom icons might break this later)
    if (!_icons.contains(_selectedIcon)) {
      if (_icons.isNotEmpty) _selectedIcon = _icons.first;
    }
  }

  void _saveSkill() async {
    final name = _nameController.text.trim();

    if (name.isNotEmpty) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final updatedSkill = Skill(
        id: widget.skill.id, // Preserve ID to keep linked sessions intact
        name: name,
        iconName: _selectedIcon,
        targetHours: widget.skill.targetHours, // Keep original
        category: widget.skill.category, // Keep original
        orderIndex: widget.skill.orderIndex, // Keep original hierarchy position
      );

      await storage.saveSkill(updatedSkill);
      widget.onEdited();
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
            'Edit Skill',
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
            placeholder: 'Skill Name (e.g. Guitar)',
            placeholderStyle: TextStyle(
              color: AppTheme.systemBlack.withOpacity(0.4),
            ),
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),

          // Icon Selection
          const Text('Select Icon',
              style: TextStyle(color: AppTheme.systemGray)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _icons.map((iconName) {
              final isSelected = _selectedIcon == iconName;
              return GestureDetector(
                onTap: () {
                  HapticWrapper.light();
                  setState(() {
                    _selectedIcon = iconName;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.focusBlue
                        : AppTheme.pureCeramicWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconMapping(iconName),
                    color: isSelected
                        ? AppTheme.pureCeramicWhite
                        : AppTheme.systemGray,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.focusBlue,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveSkill,
              child: const Text('Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconMapping(String iconName) {
    switch (iconName) {
      case 'book':
        return CupertinoIcons.book;
      case 'guitar':
        return CupertinoIcons.goforward_15;
      case 'gym':
        return CupertinoIcons.heart_fill;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      default:
        return CupertinoIcons.star;
    }
  }
}
