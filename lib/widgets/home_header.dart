import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11B1E2), Color(0xFF0E8FB5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF11B1E2).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_rounded, color: Colors.white, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 2),
                  FutureBuilder<SharedPreferences>(
                    future: SharedPreferences.getInstance(),
                    builder: (context, asyncSnapshot) {
                      String? name = asyncSnapshot.data?.getString('username');
                      return Text(
                        name ?? 'Siswa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
