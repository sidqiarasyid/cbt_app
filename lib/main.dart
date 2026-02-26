import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/controllers/auth_controller.dart';
import 'package:cbt_app/services/profile_service.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

// Import widgets
import 'widgets/navbar.dart';

// Import views
import 'views/home_page.dart';
import 'views/history_page.dart';
import 'views/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBT App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorsApp.backgroundColor),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Splash screen that checks for existing session
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authController = AuthController();
    final isLoggedIn = await authController.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Validate token against backend before auto-login
      try {
        await ProfileService().fetchProfile();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } catch (_) {
        // Token expired or invalid — redirect to login
        await authController.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Loginpage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class MyHomePage extends StatefulWidget {
 
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomePage(),
      HistoryPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorsApp.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
