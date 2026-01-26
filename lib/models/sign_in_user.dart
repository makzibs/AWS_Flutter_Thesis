import 'dart:convert';

class SignInUser {
  final String email;
  final String password;


  SignInUser({required this.email,  required this.password});


  Map<String, dynamic> toMap() {
    return<String, dynamic> {
      'email': email,
      'password': password,
      
    };
  }

  String toJson() => json.encode(toMap());


}