import 'dart:convert';

class User {
  final String email;
  final String fullName;
  final String password;

  User({required this.email, required this.fullName, required this.password});


  Map<String, dynamic> toMap() {
    return<String, dynamic> {
      'email': email,
      'fullName': fullName,
      'password': password,
    };
  }

  String toJson() => json.encode(toMap());


}