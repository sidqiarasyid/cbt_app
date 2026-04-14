import 'package:flutter/material.dart';

class ColorsApp {
  static const Color primaryColor = Color(0xFF11B1E2);
  static const Color backgroundColor = Color(0xFFECEFF5);
  static const Color secondaryColor = Color(0xFFFFFFFF);
  static const Color pillStrokeColorGreen = Color(0xFF8BCC02);
  static const Color pillFillColorGreen = Color(0xFFF7FFE8);
  static const Color pillStrokeColorRed = Color(0xFFFF5F57);
  static const Color pillFillColorRed = Color(0x26FF383C);
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 60);
}

class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve springy = Curves.elasticOut;
}

class TextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
}
