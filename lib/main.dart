import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) {
          final ts = TimerService();
          ts.restoreState(storageService);
          return ts;
        }),
      ],
      child: const OnePercentBetterApp(),
    ),
  );
}

class OnePercentBetterApp extends StatelessWidget {
  const OnePercentBetterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '1% Better',
      theme: AppTheme.cupertinoTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
