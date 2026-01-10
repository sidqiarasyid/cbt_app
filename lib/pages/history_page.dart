import 'package:cbt_app/model/ujian_response_model.dart';
import 'package:cbt_app/services/UjianService.dart';
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
  late Future<UjianResponseModel> historyItem;
  final UjianService ujianService = UjianService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    historyItem = ujianService.getUjianSiswa();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UjianResponseModel>(
      future: historyItem,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF11B1E2)),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data history...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (asyncSnapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${asyncSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          historyItem = ujianService.getUjianSiswa();
                        });
                      },
                      icon: Icon(Icons.refresh_rounded),
                      label: Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF11B1E2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final ujianData = asyncSnapshot.data!;
        final historyList = ujianData.ujians.where((item) => 
        item.statusUjian == "DINILAI").toList();

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
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              final isExpanded = _expandedCards.contains(index);
                return  Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: HistoryCard(
                  subject: item.ujian.namaUjian,
                  grade: item.ujian.tingkat,
                  teacher: item.ujian.jurusan,
                  imageUrl: 'assets/images/c1.jpg',
                  status: item.statusUjian,
                  isExpanded: isExpanded,
                  pilganScore: item.hasil?.nilaiAkhir,
                  essayStatus: 'Tidak ada essay',
                  finalScore: item.hasil?.nilaiAkhir.toStringAsFixed(2),
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
    );
  }
}

