import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbt_app/main.dart';
import 'package:cbt_app/providers/auth_provider.dart';
import 'package:cbt_app/utils/page_transitions.dart';
import 'package:cbt_app/views/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthProvider>();
    await auth.bootstrap();
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      Navigator.pushReplacement(context, fadeSlideRoute(const MyHomePage()));
    } else {
      Navigator.pushReplacement(context, fadeSlideRoute(const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
