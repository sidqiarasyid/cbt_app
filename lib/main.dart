import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:cbt_app/app.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/views/home_page.dart';
import 'package:cbt_app/views/history_page.dart';
import 'package:cbt_app/views/profile_page.dart';
import 'package:cbt_app/widgets/home/navbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CbtApp());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const HomePage(),
      const HistoryPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
        body: IndexedStack(index: _selectedIndex, children: _pages),
        child: NavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
