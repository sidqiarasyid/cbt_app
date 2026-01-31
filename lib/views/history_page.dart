import 'package:cbt_app/models/hasil_ujian_response_model.dart';
import 'package:cbt_app/services/ujian_service.dart';
import 'package:cbt_app/style/style.dart';
import 'package:cbt_app/widgets/history_card.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Track which cards are expanded
  final Set<int> _expandedCards = {};
  late Future<HasilUjianListResponse> historyItem;
  final UjianService ujianService = UjianService();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    historyItem = ujianService.getHasilUjianSiswa();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HasilUjianListResponse>(
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
                          historyItem = ujianService.getHasilUjianSiswa();
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

        final hasilData = asyncSnapshot.data!;
        final historyList = hasilData.hasil;

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
                  subject: item.pesertaUjian.ujian.namaUjian,
                  grade: item.pesertaUjian.ujian.tingkat,
                  teacher: item.pesertaUjian.ujian.jurusan,
                  imageUrl: 'assets/images/c1.jpg',
                  status: item.pesertaUjian.statusUjian,
                  isExpanded: isExpanded,
                  pilganScore: item.nilaiAkhir,
                  essayStatus: 'Tidak ada essay',
                  finalScore: item.nilaiAkhir.toStringAsFixed(2),
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

