import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbt_app/providers/auth_provider.dart';
import 'package:cbt_app/providers/connectivity_provider.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/views/splash_page.dart';

class CbtApp extends StatelessWidget {
  const CbtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()..start()),
      ],
      child: MaterialApp(
        title: 'CBT App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: ColorsApp.backgroundColor),
          useMaterial3: true,
        ),
        home: const SplashPage(),
      ),
    );
  }
}
