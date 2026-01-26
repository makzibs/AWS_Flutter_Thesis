import 'dart:convert';

class ConfirmUser {
  final String email;
  final String confirmationCode;


  ConfirmUser({required this.email,  required this.confirmationCode});


  Map<String, dynamic> toMap() {
    return<String, dynamic> {
      'email': email,
      'confirmationCode': confirmationCode,
      
    };
  }

  String toJson() => json.encode(toMap());


}