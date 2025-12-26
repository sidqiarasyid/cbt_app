import 'package:cbt_app/model/QuizModel.dart';
import 'package:cbt_app/model/UjianModel.dart';
import 'package:cbt_app/pages/quiz_page.dart';
import 'package:cbt_app/widgets/StartDialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ExamCard.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  

  @override
  Widget build(BuildContext context) {
    List<String> jawaban1 = [
      "Answer 1", 
      "Answer 2",
      "Answer 3",
      "Answer 4"
    ];
    List<QuizModel> quizList1 = [
      QuizModel(
      question: "Choose the correct sentence!, there is more than one answers to this question", 
      quizType: "Pilgan", 
      answersPilgan: jawaban1, 
      rightAnswerPilgan: 1,
      isFinished: false
      ),
       QuizModel(
      question: "This is an essay problem, you need to write up to 200 words in this quiz", 
      quizType: "Essay",  
      isFinished: false,
      answersPilgan: []
      ),
       QuizModel(question: "This problem need you to choose from 4 answers, there is more than one answers to this question 3", 
      quizType: "Pilgan", 
      answersPilgan: jawaban1, 
      rightAnswerPilgan: 3,
      isFinished: false
      ),
      QuizModel(question: "Requires you to choose one of the 4 answers, but there is always more than one answer to a problem 4", 
      quizType: "Pilgan", 
      answersPilgan: jawaban1, 
      rightAnswerPilgan: 3,
      isFinished: false
      ),
      QuizModel(question: "This question does not accept zero answer, it needs at least 1 or more answer to be picked in order for it to pass you 5", 
      quizType: "Pilgan", 
      answersPilgan: jawaban1, 
      rightAnswerPilgan: 3,
      isFinished: false
      ),
    ];
    List<UjianModel> ujianList = [
      UjianModel(
        subject: "Bahasa Inggris-Listening & Reading", 
        grade: "X IPS B", 
        date: "31 Mar 2024", 
        teacher: "Pak Budi", 
        type: "UTS", 
        ujianImage: 'assets/images/c1.jpg',
        quizList: quizList1,),
        
      UjianModel(
        subject: "Bahasa Indonesia-Advanced", 
        grade: "X IPS B", 
        date: "1 April 2024", 
        teacher: "Bu Maryam", 
        type: "UTS", 
        ujianImage: 'assets/images/c2.jpg',
        quizList: quizList1,
        ),
      UjianModel(
        subject: "Matematika Lanjutan (Susah)", 
        grade: "X IPS B", 
        date: "3 April 2024", 
        teacher: "Bu Rini", 
        type: "UTS", 
        ujianImage: 'assets/images/c1.jpg',
        quizList: quizList1,
        ),
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
                    child: FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (context, asyncSnapshot) { 
                        String? name = asyncSnapshot.data?.getString('username'); 
                        return Text(
                          'Selamat Datang ${name}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        );
                      }
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
                            startQuiz(context, ujianList[index].subject, (){
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => QuizPage(ujian: ujianList[index],)));
                            });
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

startQuiz(BuildContext context, String sub, VoidCallback btnPressed){
  showDialog(context: context, builder: (BuildContext context) {
    return StartDialog(subject: sub, btnPressed: btnPressed);
  },);
}
