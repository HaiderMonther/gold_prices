import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class GoldProvider extends ChangeNotifier {
  Map<String, dynamic>? _latestPrice;
  List<dynamic> _history = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get latestPrice => _latestPrice;
  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double getPriceForKarat(int karat) {
    if (_latestPrice == null) return 0.0;
    switch (karat) {
      case 24:
        return double.tryParse(_latestPrice!['price_24k']?.toString() ?? '0') ?? 0.0;
      case 21:
        return double.tryParse(_latestPrice!['price_21k']?.toString() ?? '0') ?? 0.0;
      case 18:
        return double.tryParse(_latestPrice!['price_18k']?.toString() ?? '0') ?? 0.0;
      default:
        return 0.0;
    }
  }

  Future<void> fetchLatestPrice() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/gold-prices/latest');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _latestPrice = jsonDecode(response.body);
      } else {
        _error = 'فشل جلب أسعار الذهب الحالية';
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالشبكة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/gold-prices');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _history = jsonDecode(response.body);
      } else {
        _error = 'فشل جلب سجل الأسعار';
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالشبكة';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePrices(double price24, double price21, double price18) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/gold-prices', {
        'price_24k': price24,
        'price_21k': price21,
        'price_18k': price18,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _latestPrice = jsonDecode(response.body);
        _history.insert(0, _latestPrice); // Prepend to history
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'فشل تحديث أسعار الذهب';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالشبكة';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
