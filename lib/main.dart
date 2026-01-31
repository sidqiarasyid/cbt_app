import 'package:cbt_app/views/login_page.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

// Import widgets
import 'widgets/navbar.dart';

// Import views
import 'views/home_page.dart';
import 'views/history_page.dart';
import 'views/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorsApp.backgroundColor),
        useMaterial3: true,
      ),
      home: Loginpage(),
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
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
