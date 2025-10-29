import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class ExamCard extends StatelessWidget {
  final String date;
  final String subject;
  final String school;
  final String teacher;
  final String grade;
  final String imageUrl;
  final VoidCallback onBtnPressed;

  const ExamCard({
    super.key,
    required this.date,
    required this.subject,
    required this.school,
    required this.teacher,
    required this.grade,
    required this.imageUrl,
    required this.onBtnPressed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Date overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[300]),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.orange[200],
                        child: const Icon(
                          Icons.landscape,
                          size: 50,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Date overlay
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(12),
                      topLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subject and Grade
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        school,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ColorsApp.pillFillColorRed,
                    border: Border.all(
                      color: ColorsApp.pillStrokeColorRed,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorsApp.pillStrokeColorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Teacher Info
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[400],
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  teacher,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Action Button
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBtnPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kerjakan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
