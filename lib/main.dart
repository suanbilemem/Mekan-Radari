import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

import 'services/background_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance
      .initialize();

  await BackgroundService
      .initialize();

  runApp(
    const YerRadariApp(),
  );
}

class YerRadariApp
    extends StatelessWidget {
  const YerRadariApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,

      title: 'Yer Radarı',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            Colors.red,
      ),

      home:
          const HomeScreen(),
    );
  }
}