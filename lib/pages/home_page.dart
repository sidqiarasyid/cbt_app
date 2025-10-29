import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/pages/quiz_start_page.dart';
import 'package:flutter/material.dart';
import '../widgets/ExamCard.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    List<UjianModel> ujianList = [
      UjianModel(
        subject: "Bahasa Inggris-Listening & Reading", 
        grade: "X IPS B", 
        date: "31 Mar 2024", 
        teacher: "Pak Budi", 
        type: "UTS", 
        ujianImage: 'assets/images/c1.jpg'),
      UjianModel(
        subject: "Bahasa Indonesia-Advanced", 
        grade: "X IPS B", 
        date: "1 April 2024", 
        teacher: "Bu Maryam", 
        type: "UTS", 
        ujianImage: 'assets/images/c2.jpg'),
      UjianModel(
        subject: "Matematika Lanjutan (Susah)", 
        grade: "X IPS B", 
        date: "3 April 2024", 
        teacher: "Bu Rini", 
        type: "UTS", 
        ujianImage: 'assets/images/c1.jpg'),
    ];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.09,
              width: double.infinity,
              margin: EdgeInsets.only(top: 30),
              padding: EdgeInsets.only(left: 16, ),
              color: Colors.grey[100],
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selamat Datang Sidqi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: -15,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          'assets/images/sekolah.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Text(
                'Jadwal Ujian',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: ujianList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: ExamCard(
                          date: ujianList[index].date,
                          subject: ujianList[index].subject,
                          school: ujianList[index].type,
                          teacher: ujianList[index].teacher,
                          grade: ujianList[index].grade,
                          imageUrl: ujianList[index].ujianImage,
                          onBtnPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => QuizStartPage(),
                              ));
                          },
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 20,);
                },
                ),
            )
          ],
        ),
      ),
    );
  }
}
