import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Configuration pour le VPS de production. Modifiez cette URL lors de votre déploiement.
  static const String baseUrl = 'http://180.149.199.233/teptep-api/api'; 
  static String? token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('api_token');
  }

  static Future<void> setToken(String? newToken) async {
    token = newToken;
    final prefs = await SharedPreferences.getInstance();
    if (newToken != null) {
      await prefs.setString('api_token', newToken);
    } else {
      await prefs.remove('api_token');
    }
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: _headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
  }
}
