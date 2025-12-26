import 'package:cbt_app/model/user_model.dart';
import 'package:cbt_app/services/LoginService.dart';
import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  LoginService loginService = new LoginService(); 
  

  Future<void> login() async{
    SharedPreferences myPref = await SharedPreferences.getInstance();
    if(userController.text.isNotEmpty && passController.text.isNotEmpty){
      try{
         setState(() {
          isLoading = !isLoading;
         });
         UserModel res = await loginService.loginSiswa(userController.text, passController.text);   
         if(res.user.profile.namaLengkap.isNotEmpty){
          await myPref.setString('token', res.token);
          await myPref.setString('username', res.user.profile.namaLengkap);
         Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(),));

      }
      } catch (e){
        if(e.toString().contains('invalid-credentials')) {
           const snackbar = SnackBar(content: Text("Password yang dimasukkan salah"));
           ScaffoldMessenger.of(context).showSnackBar(snackbar);
        } else if(e.toString().contains('user-notfound')) {
          const snackbar = SnackBar(content: Text("User tidak ditemukan"));
           ScaffoldMessenger.of(context).showSnackBar(snackbar);
        } else {
          String error = e.toString();
          var snackbar = SnackBar(content: Text("Terjadi kesalahan, silahkan coba lagi nanti ${error}"));
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
      }
      setState(() {
       isLoading = !isLoading;
      });

    } else {
      const snackbar = SnackBar(content: Text("Isi Username atau Password Terlebih dahulu"));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading ? Center(child: CircularProgressIndicator()) :  Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/sekolah.png', height: 113,),
                SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Log In',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passController,
                  obscureText: !isPasswordVisible,
                  obscuringCharacter: '*',
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsApp.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => login(),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
