import 'package:flutter/material.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request activity recognition permission at app start
  await Permission.activityRecognition.request();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Health App',
          themeMode: themeManager.currentTheme,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: AuthPage(),
        );
      },
    );
  }
}
