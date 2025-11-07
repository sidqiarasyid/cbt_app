import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/HistoryCard.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Track which cards are expanded
  final Set<int> _expandedCards = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsApp.backgroundColor,
        elevation: 0,
        title: const Text(
          'Riwayat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyData.length,
        itemBuilder: (context, index) {
          final item = _historyData[index];
          final isExpanded = _expandedCards.contains(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HistoryCard(
              subject: item['subject'] as String,
              grade: item['grade'] as String,
              teacher: item['teacher'] as String,
              imageUrl: item['imageUrl'] as String,
              status: item['status'] as String,
              isExpanded: isExpanded,
              pilganScore: item['pilganScore'] as int?,
              essayStatus: item['essayStatus'] as String?,
              finalScore: item['finalScore'] as String?,
              onExpandToggle: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCards.remove(index);
                  } else {
                    _expandedCards.add(index);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}

// Sample data for history
final List<Map<String, dynamic>> _historyData = [
  {
    'subject': 'Bahasa Inggris:\nAdvanced',
    'grade': 'Advanced',
    'teacher': 'Pak Budi',
    'imageUrl': 'assets/images/c1.jpg',
    'status': 'selesai',
    'pilganScore': 100,
    'essayStatus': 'Unreviewed',
    'finalScore': '-',
  },
  {
    'subject': 'Bahasa Inggris:\nAdvanced',
    'grade': 'Advanced',
    'teacher': 'Pak Budi',
    'imageUrl': 'assets/images/c1.jpg',
    'status': 'selesai',
    'pilganScore': 85,
    'essayStatus': 'Reviewed',
    'finalScore': '90',
  },
];
