import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _tenant;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get tenant => _tenant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  
  bool get isAdmin => _user != null && ['admin', 'super_admin'].contains(_user!['role']);
  bool get isSuperAdmin => _user != null && _user!['role'] == 'super_admin';
  bool get isAccountant => _user != null && ['admin', 'super_admin', 'accountant'].contains(_user!['role']);

  // Tenant branding
  String get tenantName => _tenant?['name'] ?? 'ذهـبي';
  String? get tenantLogoUrl => _tenant?['logo_url'];
  String? get tenantPrimaryColor => _tenant?['primary_color'];

  Future<void> loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('gold_token');
    final userStr = prefs.getString('gold_user');
    final tenantStr = prefs.getString('gold_tenant');
    if (userStr != null) {
      try { _user = jsonDecode(userStr); } catch (e) { _user = null; }
    }
    if (tenantStr != null) {
      try { _tenant = jsonDecode(tenantStr); } catch (e) { _tenant = null; }
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password, String tenantCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
        'tenant_code': tenantCode,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _token = data['access_token'];
        _user = data['user'];
        _tenant = data['tenant'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gold_token', _token!);
        await prefs.setString('gold_user', jsonEncode(_user));
        if (_tenant != null) {
          await prefs.setString('gold_tenant', jsonEncode(_tenant));
        } else {
          await prefs.remove('gold_tenant');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'فشل تسجيل الدخول';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالخادم. تأكد من إعدادات IP السيرفر.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _tenant = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gold_token');
    await prefs.remove('gold_user');
    await prefs.remove('gold_tenant');
    notifyListeners();
  }

  void forceLogout() {
    logout();
  }
}
