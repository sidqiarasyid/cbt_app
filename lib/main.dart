import 'package:cbt_app/pages/LoginPage.dart';
import 'package:flutter/material.dart';

// Import widgets
import 'widgets/navbar.dart';

// Import pages
import 'pages/home_page.dart';
import 'pages/history_page.dart';
import 'pages/profile_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Loginpage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // This is the state variable that will hold the current page index
  int _selectedIndex = 0;

  // This is the list of pages to navigate between
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    HistoryPage(),
    ProfilePage(),
  ];

  // This function is called by the NavBar when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      // Set the state to the new index
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is now the currently selected page from our list
      body: _pages.elementAt(_selectedIndex),

      // Use your custom NavBar widget here
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
