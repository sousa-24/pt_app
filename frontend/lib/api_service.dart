import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<dynamic> get(
    BuildContext context,
    String endpoint,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      _redirectToLogin(context);
      return null;
    }

    return jsonDecode(response.body);
  }

  static Future<dynamic> post(
    BuildContext context,
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      _redirectToLogin(context);
      return null;
    }

    return jsonDecode(response.body);
  }

  static void _redirectToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(onToggleTheme: () {}, themeMode: ThemeMode.light),
      ),
      (route) => false,
    );
  }
}
