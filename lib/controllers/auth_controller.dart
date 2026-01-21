import 'dart:convert';
import 'package:demo_flutter_aws/models/user.dart';
import 'package:demo_flutter_aws/views/confirm_sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthController {


  Future<void> signUpUsers({
    required String email,
     required String fullName,
      required String password,
      required BuildContext context,
      }) async {
     try {

      User user = User(email: email, fullName: fullName, password: password);
      http.Response response =  await http.post(Uri.parse('https://oyxr8n67xk.execute-api.eu-north-1.amazonaws.com/sign-up'),
      body: user.toJson(),
      headers: <String, String> {
        "Content-Type": "application/json; charset=UTF-8",
      },
      );
      
      if (response.statusCode == 200) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return ConfirmSignUpScreen();
          },
          ),
          );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json.decode(response.body)['details'])));
      }
     } catch (e) {

      print(e.toString());
       
     }


  }
}
