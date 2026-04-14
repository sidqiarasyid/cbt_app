import 'package:flutter/material.dart';
import '../style/style.dart';

Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.standard);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Route<T> sharedAxisRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.emphasized);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Route<T> scaleFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    opaque: false,
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.standard);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
