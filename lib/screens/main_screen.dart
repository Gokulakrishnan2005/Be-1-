import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/haptic_wrapper.dart';
import '../widgets/modals/add_skill_modal.dart';
import '../widgets/modals/add_transaction_modal.dart';
import '../widgets/modals/tri_state_routing_modal.dart';
import '../services/timer_service.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'organizer_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isModalOpen = false;
  bool _showGenesisBloom = false;
  StreamSubscription<void>? _genesisSubscription;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<FinanceScreenState> _financeKey =
      GlobalKey<FinanceScreenState>();
  final GlobalKey<OrganizerScreenState> _organizerKey =
      GlobalKey<OrganizerScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    FinanceScreen(key: _financeKey),
    OrganizerScreen(key: _organizerKey),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay subscription to ensure context read is safe, or read inside build.
    // Better to read after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = context.read<TimerService>();
      _genesisSubscription = timerService.genesisEventStream.listen((_) {
        _triggerGenesisBloom();
      });
    });
  }

  @override
  void dispose() {
    _genesisSubscription?.cancel();
    super.dispose();
  }

  void _triggerGenesisBloom() async {
    if (!mounted) return;
    HapticWrapper.heavy();
    setState(() {
      _showGenesisBloom = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showGenesisBloom = false;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticWrapper.medium();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onFabTapped() {
    HapticWrapper.heavy();

    // Open context-aware modal based on _currentIndex
    switch (_currentIndex) {
      case 0:
        showCupertinoModalPopup(
          context: context,
          builder: (builder) => AddSkillModal(
            onAdded: () => _homeKey.currentState?.refresh(),
          ),
        );
        break;
      case 1:
        showCupertinoModalPopup(
          context: context,
          builder: (builder) => AddTransactionModal(
            onAdded: () => _financeKey.currentState?.refresh(),
          ),
        );
        break;
      case 2:
        setState(() => _isModalOpen = true);
        showCupertinoModalPopup(
          context: context,
          barrierColor: Colors.black.withOpacity(0.4),
          builder: (builder) => TriStateRoutingModal(
            onAdded: () => _organizerKey.currentState?.refresh(),
            onDismiss: () => setState(() => _isModalOpen = false),
          ),
        ).then((_) {
          // Fallback in case they tap barrier directly
          if (mounted) setState(() => _isModalOpen = false);
        });
        break;
      case 3:
        // Settings/Profile specific action or empty
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Dark background behind the scaled UI
      child: AnimatedScale(
        scale: _isModalOpen ? 0.95 : 1.0,
        curve: Curves.easeOutQuart,
        duration: const Duration(milliseconds: 350),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isModalOpen ? 24 : 0),
          child: CupertinoPageScaffold(
            child: Stack(
              children: [
                // Content
                Positioned.fill(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),

                // Custom Bottom Navigation Bar with Frosted Glass
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        height: 90, // safe area padding usually needed for iOS
                        decoration: BoxDecoration(
                          color: AppTheme.pureCeramicWhite.withOpacity(0.7),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.systemGray.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavItem(0, CupertinoIcons.time), // Home
                              _buildNavItem(
                                  1,
                                  CupertinoIcons
                                      .money_dollar_circle), // Finance
                              const SizedBox(width: 48), // Space for center FAB
                              _buildNavItem(
                                  2, CupertinoIcons.square_list), // Organizer
                              _buildNavItem(
                                  3, CupertinoIcons.person), // Profile
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Action Button
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _onFabTapped,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.focusBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.focusBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: AppTheme.pureCeramicWhite,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

                // Genesis Event Bloom Overlay
                // Ignores pointers so user can still interact if they want,
                // but realistically it's a transient 0.8s flash.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showGenesisBloom ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutExpo,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppTheme.growthGreen.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 55,
        width: 60,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? AppTheme.focusBlue : AppTheme.systemGray,
        ),
      ),
    );
  }
}
