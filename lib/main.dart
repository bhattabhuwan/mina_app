import 'package:flutter/material.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/auth/auth_service.dart';      // adjust import to your AuthPage location
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request activity recognition permission at app start
  await Permission.activityRecognition.request();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Load user data once the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });

    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Health App',
          themeMode: themeManager.currentTheme,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const AuthPage(),
        );
      },
    );
  }
}

// Light Theme Definition
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey.shade100,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);

// Dark Theme Definition
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey.shade900,
  appBarTheme: AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.grey.shade800,
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade800,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);