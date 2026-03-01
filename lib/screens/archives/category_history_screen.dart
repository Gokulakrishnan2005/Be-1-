import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/session.dart';
import '../../models/skill.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class CategoryHistoryScreen extends StatefulWidget {
  final String category; // 'GROWTH', 'MAINTENANCE', 'ENTROPY'
  final Color themeColor;

  const CategoryHistoryScreen({
    super.key,
    required this.category,
    required this.themeColor,
  });

  @override
  State<CategoryHistoryScreen> createState() => _CategoryHistoryScreenState();
}

class _CategoryHistoryScreenState extends State<CategoryHistoryScreen> {
  late final StorageService _storageService;
  List<Session> _sessions = [];
  Map<String, Skill> _skillCache = {};

  // Grouped chronologically: { "SEPTEMBER 24" : [Session1, Session2] }
  final Map<String, List<Session>> _groupedSessions = {};
  final List<String> _sortedDateKeys = [];

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _loadData();
  }

  void _loadData() {
    final allSessions = _storageService.getSessions();
    final allSkills = _storageService.getSkills();

    // Cache to prevent repetitive firstWhere lookups
    _skillCache = {for (var s in allSkills) s.id: s};

    // Filter to category requested
    final filtered = allSessions.where((s) {
      final skill = _skillCache[s.skillId];
      if (skill == null) return false;

      // Special case: if target is GROWTH and skill category is empty/null, it defaults to GROWTH.
      // Or if explicitly GROWTH.
      if (widget.category == 'GROWTH') {
        return skill.category.isEmpty || skill.category == 'GROWTH';
      }
      return skill.category == widget.category;
    }).toList();

    // Sort descending (newest overall first)
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

    _sessions = filtered;
    _groupSessions();

    setState(() {});
  }

  void _groupSessions() {
    _groupedSessions.clear();
    _sortedDateKeys.clear();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var session in _sessions) {
      final sd = session.startTime;
      final sessionDay = DateTime(sd.year, sd.month, sd.day);

      String dateKey;
      if (sessionDay == today) {
        dateKey = "TODAY";
      } else if (sessionDay == yesterday) {
        dateKey = "YESTERDAY";
      } else {
        dateKey =
            DateFormat('MMMM d').format(sd).toUpperCase(); // e.g., SEPTEMBER 24
      }

      if (!_groupedSessions.containsKey(dateKey)) {
        _groupedSessions[dateKey] = [];
        _sortedDateKeys.add(
            dateKey); // Keeps order of first insertion (since we pre-sorted)
      }
      _groupedSessions[dateKey]!.add(session);
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return "0m";
    int hours = totalSeconds ~/ 3600;
    int minutes = ((totalSeconds % 3600) / 60).round();

    if (hours > 0 && minutes > 0) return "${hours}h ${minutes}m";
    if (hours > 0) return "${hours}h";
    return "${minutes}m";
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startFmt = DateFormat('hh:mm a').format(start);
    final endFmt = DateFormat('hh:mm a').format(end);
    return "$startFmt - $endFmt";
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: widget.themeColor.withOpacity(0.1),
        border: null,
        middle: Text('${_capitalize(widget.category)} History',
            style: TextStyle(
                color: widget.themeColor, fontWeight: FontWeight.w600)),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        bottom: false,
        child: _sessions.isEmpty
            ? Center(
                child: Text('No ${_capitalize(widget.category)} events logged.',
                    style: const TextStyle(color: AppTheme.systemGray)),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _buildSliverSections(),
              ),
      ),
    );
  }

  List<Widget> _buildSliverSections() {
    List<Widget> slivers = [];

    // Subtle header padding
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));

    for (var dateKey in _sortedDateKeys) {
      final daySessions = _groupedSessions[dateKey]!;

      // Sticky Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
            child: Text(
              dateKey,
              style: const TextStyle(
                color: AppTheme.systemGray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );

      // Section List
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = daySessions[index];
                final skill = _skillCache[session.skillId];
                final isLast = index == daySessions.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.pureCeramicWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(index == 0 ? 16 : 0),
                      topRight: Radius.circular(index == 0 ? 16 : 0),
                      bottomLeft: Radius.circular(isLast ? 16 : 0),
                      bottomRight: Radius.circular(isLast ? 16 : 0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side (Icon + Name)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconData(skill?.iconName ?? ''),
                                    size: 20,
                                    color: widget.themeColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      skill?.name ?? 'Unknown Skill',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.systemBlack,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right side (Duration + Time + Edited Icon)
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDuration(session.durationSeconds),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.systemBlack,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (session.isEdited) ...[
                                      const Icon(
                                        CupertinoIcons.pencil,
                                        size: 10,
                                        color: AppTheme.systemGray,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      _formatTimeRange(
                                          session.startTime, session.endTime),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.systemGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.only(
                              left: 48), // Align separator with text
                          child: SizedBox(
                              height: 1,
                              width: double.infinity,
                              child: ColoredBox(color: AppTheme.systemGray6)),
                        ),
                    ],
                  ),
                );
              },
              childCount: daySessions.length,
            ),
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));

    return slivers;
  }
}
