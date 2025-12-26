import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/utlis/url.dart';
import 'package:http/http.dart' as http;

import 'package:cbt_app/model/user_model.dart';

class LoginService {

  final url = Uri.parse('${Url.deviceUrl}/auth/login');

  Future<UserModel> loginSiswa(String username, String password) async{
    final Map<String, dynamic> body = {
      "username" : username,
      "password" : password
    };

    final String bodyJson = jsonEncode(body);
    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: bodyJson);

      if (response.statusCode == 200){
        final Map<String, dynamic> bodyMap = jsonDecode(response.body);
        return UserModel.fromJson(bodyMap);
      } else if(response.statusCode == 401){
        throw Exception('invalid-credentials');
      }  else if(response.statusCode == 404){
        throw Exception('user-notfound');
      } else {
        print('Login failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw HttpException('Error Message: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('Request timed out: $e');
      throw HttpException('Request timed out');
    } 
  }
}