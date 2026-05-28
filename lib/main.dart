import 'package:flutter/material.dart';
import 'package:mina_app/auth/role_based_home.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/auth/auth_service.dart';      
import 'package:mina_app/auth/ApiService.dart';           
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
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Health App',
          themeMode: themeManager.currentTheme,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const AuthDecision(),   // Decide initial screen
        );
      },
    );
  }
}

// Widget that decides whether to show AuthPage or RoleBasedHome
class AuthDecision extends StatefulWidget {
  const AuthDecision({super.key});

  @override
  State<AuthDecision> createState() => _AuthDecisionState();
}

class _AuthDecisionState extends State<AuthDecision> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _checkLoginStatus();
  }

  Future<bool> _checkLoginStatus() async {
    final api = ApiService();
    final isLoggedIn = await api.isLoggedIn(); // returns true if token exists
    if (isLoggedIn) {
      // Optionally load user data here or let RoleBasedHome do it
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();
    }
    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const RoleBasedHome() : const AuthPage();
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