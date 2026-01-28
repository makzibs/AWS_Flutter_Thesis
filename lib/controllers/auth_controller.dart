import 'dart:convert';
import 'package:demo_flutter_aws/models/confirm_user.dart';
import 'package:demo_flutter_aws/models/sign_in_user.dart';
import 'package:demo_flutter_aws/models/user.dart';
import 'package:demo_flutter_aws/views/confirm_sign_up_screen.dart';
import 'package:demo_flutter_aws/views/home_page.dart';
import 'package:demo_flutter_aws/views/signin_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthController {


  Future<void> signUpUsers({
    required String email,
     required String fullName,
      required String password,
      required context,
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
        await Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return ConfirmSignUpScreen(email: email);
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

  Future<void> confirmSignUp({
    required String email,
    required String confirmationCode,
    required context,
  }) async {
    try {
      //final body =
          //jsonEncode({'email': email, 'confirmationCode': confirmationCode});
          ConfirmUser confirmUser = ConfirmUser(email: email, confirmationCode: confirmationCode);
      http.Response response = await http.post(
        Uri.parse(
            'https://oyxr8n67xk.execute-api.eu-north-1.amazonaws.com/confirm-sign-up'),
        body: confirmUser.toJson(),
        headers: <String, String>{
          "Content-Type": "application/json; charset=UTF-8",
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account verified successfully! Please sign in.')),
        );
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error['details'] ?? 'Verification failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }


    Future<void> signInUser({required String email, required String password, required context}) async {
      try {
        
        SignInUser signInUser = SignInUser(email: email, password: password);
        http.Response response = await http.post(Uri.parse('https://oyxr8n67xk.execute-api.eu-north-1.amazonaws.com/sign-in'),
         body: signInUser.toJson(),
          headers: <String, String> {
          "Content-Type": "application/json; charset=UTF-8",
        },);
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully')),
        );
        await Navigator.push(
         
          context, MaterialPageRoute(builder: (context) {
            return const MyHomePage();
          }
        ));
          
        } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error['details'] ?? 'Signin failed')));
      }
        
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
        
      }
    }


}

