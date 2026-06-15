import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'main.dart';
import 'app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  static Future<dynamic> get(
    BuildContext context,
    String endpoint,
    String token,
  ) async {
    final response = await http.get(
      AppConfig.apiUri(endpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      _redirectToLogin(context);
      return null;
    }

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel concluir o pedido.'};
    }

    return data;
  }

  static Future<dynamic> post(
    BuildContext context,
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      AppConfig.apiUri(endpoint),
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

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel concluir o pedido.'};
    }

    return data;
  }

  static Future<dynamic> put(
    BuildContext context,
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
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

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel concluir o pedido.'};
    }

    return data;
  }

  static Future<dynamic> patch(
    BuildContext context,
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      AppConfig.apiUri(endpoint),
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

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel concluir o pedido.'};
    }

    return data;
  }

  static Future<dynamic> uploadProfilePicture(
    BuildContext context,
    String token,
    XFile image,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      AppConfig.apiUri('/api/v1/profile/me/picture'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeTypeForPath(image.name);
    final contentType = MediaType.parse(mimeType);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
        contentType: contentType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      _redirectToLogin(context);
      return null;
    }

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel enviar a imagem.'};
    }

    return data;
  }

  static Future<dynamic> delete(
    BuildContext context,
    String endpoint,
    String token,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      _redirectToLogin(context);
      return null;
    }

    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return data is Map<String, dynamic>
          ? data
          : {'detail': 'Nao foi possivel concluir o pedido.'};
    }

    return data;
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

  static String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
