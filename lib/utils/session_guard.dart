import 'package:flutter/material.dart';
import 'package:cbt_app/utils/page_transitions.dart';
import 'package:cbt_app/utils/session_manager.dart';
import 'package:cbt_app/views/login_page.dart';

/// Thrown when the server rejects the token (401), e.g. the account logged in
/// on another device and this session was superseded.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Sesi berakhir']);
  @override
  String toString() => message;
}

/// Centralizes the reaction to a superseded/expired session: clear the local
/// session and send the user back to the login screen from anywhere.
class SessionGuard {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static bool _loggingOut = false;

  static Future<void> forceLogout({String? message}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await SessionManager.clearAll();
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          fadeSlideRoute(const LoginPage()),
          (route) => false,
        );
      }
      if (message != null) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      _loggingOut = false;
    }
  }
}
