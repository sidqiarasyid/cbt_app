import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/controllers/auth_controller.dart';
import 'package:cbt_app/services/profile_service.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

// Import widgets
import 'widgets/navbar.dart';
import 'utils/page_transitions.dart';

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
          fadeSlideRoute(const MyHomePage()),
        );
      } catch (_) {
        // Token expired or invalid — redirect to login
        await authController.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const Loginpage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        fadeSlideRoute(const Loginpage()),
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: ColorsApp.backgroundColor,
      body: BottomBar(
        showIcon: false,
        layout: BottomBarLayout(
          width: screenWidth - 40,
          offset: 16,
          borderRadius: BorderRadius.circular(28),
          clip: Clip.none,
          respectSafeArea: true,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        child: NavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
