import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://172.20.10.4:3000/api';
  static String _baseUrl = _defaultBaseUrl;
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? _defaultBaseUrl;
  }

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', newUrl);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gold_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
  }
}
