import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/skill.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class AddSkillModal extends StatefulWidget {
  final VoidCallback onAdded;

  const AddSkillModal({super.key, required this.onAdded});

  @override
  State<AddSkillModal> createState() => _AddSkillModalState();
}

class _AddSkillModalState extends State<AddSkillModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  String _selectedIcon = 'book';
  String _selectedCategory = 'GROWTH';

  final List<String> _icons = ['book', 'code', 'gym', 'guitar'];

  void _saveSkill() async {
    final name = _nameController.text.trim();
    final hoursText = _hoursController.text.trim();
    final hours = int.tryParse(hoursText) ?? 10000;

    if (name.isNotEmpty) {
      HapticWrapper.medium();
      final storage = context.read<StorageService>();

      final newSkill = Skill(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        iconName: _selectedIcon,
        targetHours: hours,
        category: _selectedCategory,
      );

      await storage.saveSkill(newSkill);
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
            'New Skill',
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
              color: AppTheme.systemBlack
                  .withOpacity(0.4), // Adjust opacity here for intensity
            ),
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          CupertinoTextField(
            controller: _hoursController,
            placeholder: 'Target Hours (default: 10000)',
            keyboardType: TextInputType.number,
            placeholderStyle: TextStyle(
              color: AppTheme.systemBlack
                  .withOpacity(0.4), // Adjust opacity here for intensity
            ),
            style: const TextStyle(color: AppTheme.systemBlack),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),

          // Category Selection
          const Text('Category', style: TextStyle(color: AppTheme.systemGray)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedCategory,
              backgroundColor: AppTheme.systemGray6,
              thumbColor: _selectedCategory == 'GROWTH'
                  ? AppTheme.stateGrowth
                  : _selectedCategory == 'MAINTENANCE'
                      ? AppTheme.stateMaintenance
                      : AppTheme.stateEntropy,
              children: <String, Widget>{
                'GROWTH': Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Growth',
                    style: TextStyle(
                      color: _selectedCategory == 'GROWTH'
                          ? AppTheme.pureCeramicWhite
                          : AppTheme.systemBlack.withOpacity(0.9),
                      fontWeight: _selectedCategory == 'GROWTH'
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                'MAINTENANCE': Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Maintain',
                    style: TextStyle(
                      color: _selectedCategory == 'MAINTENANCE'
                          ? AppTheme.pureCeramicWhite
                          : AppTheme.systemBlack.withOpacity(0.9),
                      fontWeight: _selectedCategory == 'MAINTENANCE'
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                'ENTROPY': Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Entropy',
                    style: TextStyle(
                      color: _selectedCategory == 'ENTROPY'
                          ? AppTheme.pureCeramicWhite
                          : AppTheme.systemBlack.withOpacity(0.4),
                      fontWeight: _selectedCategory == 'ENTROPY'
                          ? FontWeight.w900
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              },
              onValueChanged: (String? value) {
                if (value != null) {
                  HapticWrapper.light();
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Icon Selection (simplified)
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
              color: AppTheme.systemBlack,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saveSkill,
              child: const Text('Add Skill',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureCeramicWhite)),
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
