import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'models/skill.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  try {
    storageService = await StorageService.init();
  } catch (e) {
    debugPrint('Failed to initialize StorageService: $e');
    storageService = await StorageService.init();
  }

  final timerService = TimerService();
  timerService.restoreState(storageService);

  // Genesis State: First-time user experience
  if (!storageService.isGenesisComplete()) {
    final unassignedId = 'unassigned_${DateTime.now().millisecondsSinceEpoch}';
    final unassignedSkill = Skill(
      id: unassignedId,
      name: 'Unassigned',
      iconName: 'star',
      targetHours: 10000,
      category: 'MAINTENANCE',
      orderIndex: 0,
    );
    await storageService.saveSkill(unassignedSkill);
    timerService.switchTimer(unassignedId, storageService);
    await storageService.setGenesisComplete();
  }

  final needsOnboarding = !storageService.isOnboardingComplete();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<TimerService>.value(value: timerService),
      ],
      child: OnePercentBetterApp(showOnboarding: needsOnboarding),
    ),
  );
}

class OnePercentBetterApp extends StatelessWidget {
  final bool showOnboarding;
  const OnePercentBetterApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '1% Better',
      theme: AppTheme.cupertinoTheme,
      debugShowCheckedModeBanner: false,
      home: showOnboarding ? const OnboardingScreen() : const MainScreen(),
      routes: {
        '/home': (context) => const MainScreen(),
      },
    );
  }
}
