import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'screens/home_screen.dart';

import 'services/background_service.dart';
import 'services/notification_service.dart';

import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance
      .initialize();

  await BackgroundService
      .initialize();

  runApp(
  ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: const YerRadariApp(),
  ),
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

    final themeProvider =
    Provider.of<ThemeProvider>(
      context,
    );

    return MaterialApp(
      debugShowCheckedModeBanner:
          false,

      title: 'Yer Radarı',

      theme: ThemeData(
  useMaterial3: true,
  colorSchemeSeed:
      Colors.red,
),

darkTheme: ThemeData(
  useMaterial3: true,
  brightness:
      Brightness.dark,
  colorSchemeSeed:
      Colors.red,
),

themeMode:
    themeProvider.darkMode
        ? ThemeMode.dark
        : ThemeMode.light,

      home:
          const HomeScreen(),
    );
  }
}