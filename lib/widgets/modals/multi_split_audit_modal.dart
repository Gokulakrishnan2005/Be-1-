import 'package:flutter/cupertino.dart';

import '../../models/skill.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

/// Represents one row in the multi-split allocator.
class _SplitRow {
  Skill? skill;
  int minutes;

  _SplitRow({this.skill, this.minutes = 0});
}

/// A modal that allows splitting a session across N different skills.
/// The total must equal the original duration exactly.
class MultiSplitAuditModal extends StatefulWidget {
  final Skill originalSkill;
  final Duration totalDuration;
  final List<Skill> allSkills;

  /// Called with a list of (skillId, durationInSeconds) pairs.
  final Function(List<MapEntry<String, int>> splits) onConfirm;

  const MultiSplitAuditModal({
    super.key,
    required this.originalSkill,
    required this.totalDuration,
    required this.allSkills,
    required this.onConfirm,
  });

  @override
  State<MultiSplitAuditModal> createState() => _MultiSplitAuditModalState();
}

class _MultiSplitAuditModalState extends State<MultiSplitAuditModal> {
  late List<_SplitRow> _rows;

  @override
  void initState() {
    super.initState();
    // Initialize with the original skill taking all the time
    _rows = [
      _SplitRow(
        skill: widget.originalSkill,
        minutes: widget.totalDuration.inMinutes,
      ),
    ];
  }

  int get _totalMinutes => widget.totalDuration.inMinutes;
  int get _assignedMinutes => _rows.fold(0, (sum, r) => sum + r.minutes);
  int get _unassignedMinutes => _totalMinutes - _assignedMinutes;
  bool get _isValid =>
      _unassignedMinutes == 0 && _rows.every((r) => r.skill != null);

  String _formatDuration(int minutes) {
    if (minutes < 0) return '-${_formatDuration(-minutes)}';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  void _addRow() {
    HapticWrapper.light();
    setState(() {
      _rows.add(_SplitRow(
        skill: null,
        minutes: _unassignedMinutes > 0 ? _unassignedMinutes : 0,
      ));
    });
  }

  void _removeRow(int index) {
    if (index == 0) return; // Can't remove original
    HapticWrapper.light();
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _showSkillPicker(int rowIndex) {
    // Group skills by category
    final growthSkills =
        widget.allSkills.where((s) => s.category == 'GROWTH').toList();
    final maintSkills =
        widget.allSkills.where((s) => s.category == 'MAINTENANCE').toList();
    final entropySkills =
        widget.allSkills.where((s) => s.category == 'ENTROPY').toList();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.systemGray6,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.systemBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (growthSkills.isNotEmpty) ...[
                        _buildCategoryHeader('GROWTH', AppTheme.stateGrowth),
                        ...growthSkills
                            .map((s) => _buildSkillOption(s, ctx, rowIndex)),
                      ],
                      if (maintSkills.isNotEmpty) ...[
                        _buildCategoryHeader(
                            'MAINTENANCE', AppTheme.stateMaintenance),
                        ...maintSkills
                            .map((s) => _buildSkillOption(s, ctx, rowIndex)),
                      ],
                      if (entropySkills.isNotEmpty) ...[
                        _buildCategoryHeader('ENTROPY', AppTheme.stateEntropy),
                        ...entropySkills
                            .map((s) => _buildSkillOption(s, ctx, rowIndex)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSkillOption(Skill skill, BuildContext ctx, int rowIndex) {
    return GestureDetector(
      onTap: () {
        HapticWrapper.light();
        setState(() {
          _rows[rowIndex].skill = skill;
        });
        Navigator.pop(ctx);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppTheme.pureCeramicWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_getIconData(skill.iconName),
                size: 20,
                color: skill.category == 'GROWTH'
                    ? AppTheme.stateGrowth
                    : skill.category == 'ENTROPY'
                        ? AppTheme.stateEntropy
                        : AppTheme.stateMaintenance),
            const SizedBox(width: 12),
            Text(
              skill.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.systemBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
          // ─── HEADER ────────────────────────────────────────────
          const Text(
            'Audit Session',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Time: ${_formatDuration(_totalMinutes)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.systemGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _unassignedMinutes == 0
                      ? AppTheme.stateGrowth.withOpacity(0.1)
                      : AppTheme.stateEntropy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Unassigned: ${_formatDuration(_unassignedMinutes)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _unassignedMinutes == 0
                        ? AppTheme.stateGrowth
                        : AppTheme.stateEntropy,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── SPLIT ROWS ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  for (int i = 0; i < _rows.length; i++) _buildSplitRow(i),
                  const SizedBox(height: 12),
                  // Add Split button
                  GestureDetector(
                    onTap: _addRow,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.pureCeramicWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.focusBlue.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add_circled,
                              color: AppTheme.focusBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Split',
                            style: TextStyle(
                              color: AppTheme.focusBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── ACTION BUTTONS ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: _isValid ? AppTheme.systemBlack : AppTheme.systemGray,
              borderRadius: BorderRadius.circular(16),
              onPressed: _isValid
                  ? () {
                      HapticWrapper.heavy();
                      final splits = _rows
                          .where((r) => r.skill != null && r.minutes > 0)
                          .map((r) => MapEntry(r.skill!.id, r.minutes * 60))
                          .toList();
                      widget.onConfirm(splits);
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Confirm Audit',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureCeramicWhite)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.pureCeramicWhite,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticWrapper.medium();
                Navigator.pop(context);
              },
              child: const Text('Cancel',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.systemBlack)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow(int index) {
    final row = _rows[index];
    final isOriginal = index == 0;

    Color rowColor = AppTheme.systemGray;
    if (row.skill != null) {
      switch (row.skill!.category) {
        case 'GROWTH':
          rowColor = AppTheme.stateGrowth;
          break;
        case 'ENTROPY':
          rowColor = AppTheme.stateEntropy;
          break;
        case 'MAINTENANCE':
          rowColor = AppTheme.stateMaintenance;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.pureCeramicWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Skill selector / name
            Expanded(
              flex: 3,
              child: isOriginal
                  ? Row(
                      children: [
                        Icon(_getIconData(row.skill!.iconName),
                            size: 20, color: rowColor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            row.skill!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: rowColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => _showSkillPicker(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.systemGray6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: row.skill != null
                            ? Row(
                                children: [
                                  Icon(_getIconData(row.skill!.iconName),
                                      size: 16, color: rowColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      row.skill!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: rowColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(CupertinoIcons.chevron_down,
                                      size: 12, color: rowColor),
                                ],
                              )
                            : const Row(
                                children: [
                                  Icon(CupertinoIcons.plus_circle,
                                      size: 16, color: AppTheme.focusBlue),
                                  SizedBox(width: 6),
                                  Text(
                                    'Select Activity',
                                    style: TextStyle(
                                      color: AppTheme.focusBlue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
            ),

            const SizedBox(width: 8),

            // Time stepper
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (row.minutes > 0) {
                        HapticWrapper.light();
                        setState(() => row.minutes -= 5);
                        if (row.minutes < 0) row.minutes = 0;
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.systemGray6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(CupertinoIcons.minus,
                          size: 14, color: AppTheme.systemGray),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      _formatDuration(row.minutes),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Courier',
                        color: AppTheme.systemBlack,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticWrapper.light();
                      setState(() => row.minutes += 5);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.systemGray6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(CupertinoIcons.plus,
                          size: 14, color: AppTheme.systemGray),
                    ),
                  ),
                ],
              ),
            ),

            // Remove button (not for original row)
            if (!isOriginal) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeRow(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CupertinoColors.destructiveRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.minus_circle_fill,
                      size: 18, color: CupertinoColors.destructiveRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
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
