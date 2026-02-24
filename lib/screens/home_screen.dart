import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skill_card.dart';
import '../widgets/day_ring_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final StorageService _storageService;
  List<Skill> _skills = [];

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _loadSkills();
  }

  void _loadSkills() {
    setState(() {
      _skills = _storageService.getSkills();
    });
  }

  // Exposed so MainScreen can call it after AddSkillModal finishes
  void refresh() {
    _loadSkills();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic background based on active timer
    final timerService = context.watch<TimerService>();
    final activeSkill = _skills.firstWhere(
      (s) => s.id == timerService.activeSkillId,
      orElse: () => Skill(id: '', name: '', iconName: '', targetHours: 0),
    );
    final isEntropy = activeSkill.category == 'ENTROPY';

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.systemGray6,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        color: isEntropy
            ? AppTheme.stateEntropy.withOpacity(0.05)
            : const Color(0x00000000),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 24.0, right: 24.0, top: 40.0, bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Reality',
                            style: TextStyle(
                              color: AppTheme.systemGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Let\'s build',
                            style: TextStyle(
                              color: AppTheme.systemBlack,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      const DayRingChart(),
                    ],
                  ),
                ),
              ),
              if (_skills.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No skills yet.\nTap + to add your first domain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.systemGray),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SkillCard(
                          skill: _skills[index],
                          onDeleted: refresh,
                        );
                      },
                      childCount: _skills.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(
                    height: 120), // padding for the bottom nav bar space
              )
            ],
          ),
        ),
      ),
    );
  }
}
