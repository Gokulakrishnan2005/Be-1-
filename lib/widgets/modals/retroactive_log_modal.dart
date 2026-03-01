import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';
import '../haptic_wrapper.dart';

class RetroactiveLogModal extends StatefulWidget {
  final String categoryName;
  final Function(Duration) onLog;
  final VoidCallback onDeleteLastLog;

  const RetroactiveLogModal({
    super.key,
    required this.categoryName,
    required this.onLog,
    required this.onDeleteLastLog,
  });

  @override
  State<RetroactiveLogModal> createState() => _RetroactiveLogModalState();
}

class _RetroactiveLogModalState extends State<RetroactiveLogModal> {
  int _selectedMinutes = 15;

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
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retroactive Log',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.systemBlack,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I just wasted time on ${widget.categoryName}. Log it now.',
            style: const TextStyle(color: AppTheme.systemGray, fontSize: 15),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedMinutes,
              backgroundColor: AppTheme.pureCeramicWhite,
              thumbColor: AppTheme.stateEntropy,
              children: <int, Widget>{
                15: _buildSegment(15, '15m'),
                30: _buildSegment(30, '30m'),
                60: _buildSegment(60, '1h'),
                120: _buildSegment(120, '2h'),
              },
              onValueChanged: (int? value) {
                if (value != null) {
                  HapticWrapper.light();
                  setState(() {
                    _selectedMinutes = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.stateEntropy,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticWrapper.heavy();
                widget.onLog(Duration(minutes: _selectedMinutes));
                Navigator.pop(context);
              },
              child: const Text('Log Entropy',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.pureCeramicWhite)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                HapticWrapper.heavy();
                widget.onDeleteLastLog();
                Navigator.pop(context);
              },
              child: const Text('Delete Last Log',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.destructiveRed)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(int value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: _selectedMinutes == value
              ? AppTheme.pureCeramicWhite
              : AppTheme.systemBlack,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
