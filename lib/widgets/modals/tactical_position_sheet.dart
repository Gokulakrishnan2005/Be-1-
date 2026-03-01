import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/skill.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

/// A persistent modal bottom sheet that allows the user to move a skill
/// up, down, to top, or to bottom via deterministic index swaps.
/// The sheet stays open while the user rapidly taps buttons.
class TacticalPositionSheet extends StatefulWidget {
  final Skill skill;
  final VoidCallback onChanged;

  const TacticalPositionSheet({
    super.key,
    required this.skill,
    required this.onChanged,
  });

  @override
  State<TacticalPositionSheet> createState() => _TacticalPositionSheetState();
}

class _TacticalPositionSheetState extends State<TacticalPositionSheet> {
  late List<Skill> _allSkills;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final storage = context.read<StorageService>();
    _allSkills = storage.getSkills(); // Already sorted by orderIndex ASC
    _currentIndex = _allSkills.indexWhere((s) => s.id == widget.skill.id);
    if (_currentIndex < 0) _currentIndex = 0;
  }

  Future<void> _persistAll() async {
    final storage = context.read<StorageService>();
    await storage.updateSkillOrder(_allSkills);
    widget.onChanged();
  }

  void _moveUp() {
    if (_currentIndex <= 0) return;
    HapticWrapper.light();
    setState(() {
      final temp = _allSkills[_currentIndex];
      _allSkills[_currentIndex] = _allSkills[_currentIndex - 1];
      _allSkills[_currentIndex - 1] = temp;
      _currentIndex -= 1;
    });
    _persistAll();
  }

  void _moveDown() {
    if (_currentIndex >= _allSkills.length - 1) return;
    HapticWrapper.light();
    setState(() {
      final temp = _allSkills[_currentIndex];
      _allSkills[_currentIndex] = _allSkills[_currentIndex + 1];
      _allSkills[_currentIndex + 1] = temp;
      _currentIndex += 1;
    });
    _persistAll();
  }

  void _moveToTop() {
    if (_currentIndex <= 0) return;
    HapticWrapper.medium();
    setState(() {
      final item = _allSkills.removeAt(_currentIndex);
      _allSkills.insert(0, item);
      _currentIndex = 0;
    });
    _persistAll();
  }

  void _moveToBottom() {
    if (_currentIndex >= _allSkills.length - 1) return;
    HapticWrapper.medium();
    setState(() {
      final item = _allSkills.removeAt(_currentIndex);
      _allSkills.add(item);
      _currentIndex = _allSkills.length - 1;
    });
    _persistAll();
  }

  @override
  Widget build(BuildContext context) {
    final skillName = widget.skill.name;
    final totalItems = _allSkills.length;
    final isFirst = _currentIndex <= 0;
    final isLast = _currentIndex >= totalItems - 1;

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
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            '$skillName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Position #${_currentIndex + 1} of $totalItems',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.systemGray,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 28),

          // Control Pad — 4 buttons
          Row(
            children: [
              _buildButton(
                icon: CupertinoIcons.arrow_up_to_line,
                label: 'Top',
                onTap: isFirst ? null : _moveToTop,
              ),
              const SizedBox(width: 12),
              _buildButton(
                icon: CupertinoIcons.arrow_up,
                label: 'Up',
                onTap: isFirst ? null : _moveUp,
              ),
              const SizedBox(width: 12),
              _buildButton(
                icon: CupertinoIcons.arrow_down,
                label: 'Down',
                onTap: isLast ? null : _moveDown,
              ),
              const SizedBox(width: 12),
              _buildButton(
                icon: CupertinoIcons.arrow_down_to_line,
                label: 'Bottom',
                onTap: isLast ? null : _moveToBottom,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Done button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.focusBlue,
              borderRadius: BorderRadius.circular(16),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isDisabled ? AppTheme.systemGray6 : AppTheme.pureCeramicWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDisabled
                  ? AppTheme.systemGray6
                  : AppTheme.systemGray.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDisabled
                    ? AppTheme.systemGray.withOpacity(0.3)
                    : AppTheme.focusBlue,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? AppTheme.systemGray.withOpacity(0.3)
                      : AppTheme.systemBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
