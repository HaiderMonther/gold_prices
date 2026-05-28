import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gold_provider.dart';
import '../theme/luxury_theme.dart';

class GoldPricesScreen extends StatefulWidget {
  const GoldPricesScreen({super.key});

  @override
  State<GoldPricesScreen> createState() => _GoldPricesScreenState();
}

class _GoldPricesScreenState extends State<GoldPricesScreen> {
  final _basePriceController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  
  double _price21k = 0;
  double _price18k = 0;
  bool _isSaving = false;
  
  double _exchangeRate = 1500;
  bool _autoFetchExchangeRate = false;
  double? _globalPrice;
  double? _openPrice;
  bool _fetchingGlobal = false;
  bool _autoUpdate = false;
  Timer? _autoUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadPrices();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _exchangeRate = prefs.getDouble('gold_exchange_rate') ?? 1500.0;
      _autoFetchExchangeRate = prefs.getBool('auto_exchange_rate') ?? false;
      _exchangeRateController.text = _exchangeRate.toStringAsFixed(2);
    });
    if (_autoFetchExchangeRate) {
      _fetchGlobalPrice(isSilent: true);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gold_exchange_rate', _exchangeRate);
    await prefs.setBool('auto_exchange_rate', _autoFetchExchangeRate);
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    _basePriceController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);
    await goldProvider.fetchHistory();
    await goldProvider.fetchLatestPrice();

    if (goldProvider.latestPrice != null) {
      final p24 = double.tryParse(goldProvider.latestPrice!['price_24k']?.toString() ?? '0') ?? 0.0;
      setState(() {
        _basePriceController.text = p24.toStringAsFixed(0);
        _calculatePrices(p24);
      });
    }
  }

  void _calculatePrices(double basePrice) {
    setState(() {
      _price21k = (basePrice * 21 / 24).roundToDouble();
      _price18k = (basePrice * 18 / 24).roundToDouble();
    });
  }
  
  Future<void> _fetchGlobalPrice({bool isSilent = false}) async {
    if (!isSilent) setState(() => _fetchingGlobal = true);
    else if (_globalPrice == null) setState(() => _fetchingGlobal = true);
    
    try {
      double currentRate = _exchangeRate;

      // 1. Fetch Exchange Rate if auto
      if (_autoFetchExchangeRate) {
        try {
          final erRes = await http.get(
            Uri.parse('https://open.er-api.com/v6/latest/USD'),
          ).timeout(const Duration(seconds: 10));
          
          if (erRes.statusCode == 200) {
            final erData = jsonDecode(erRes.body);
            if (erData['rates'] != null && erData['rates']['IQD'] != null) {
              currentRate = (erData['rates']['IQD'] as num).toDouble();
              setState(() {
                _exchangeRate = currentRate;
                _exchangeRateController.text = _exchangeRate.toStringAsFixed(2);
              });
              _savePrefs();
            }
          }
        } catch (e) {
           print('Exchange rate error: $e');
        }
      }

      // 2. Fetch Gold Price
      final res = await http.get(
        Uri.parse('https://api.gold-api.com/price/XAU/USD'),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/100.0.4896.75 Safari/537.36'},
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['price'] != null) {
           final double p = (data['price'] as num).toDouble();
           if (_openPrice == null) {
             _openPrice = p - 1.5; // Slight initial difference for UI effect
           }
           setState(() {
             _globalPrice = p;
             final double pricePerGramUsd = p / 31.1034768;
             final double pricePerGramIqd = pricePerGramUsd * currentRate;
             _basePriceController.text = pricePerGramIqd.round().toString();
             _calculatePrices(pricePerGramIqd);
           });
           if (!isSilent) _showSnackbar('تم جلب السعر العالمي وتحديث سعر الغرام بنجاح', LuxuryTheme.emerald600);
        }
      } else {
        if (!isSilent) _showSnackbar('فشل في الاتصال بالبورصة العالمية', Colors.red);
      }
    } catch (e) {
      if (!isSilent) _showSnackbar('حدث خطأ في الشبكة', Colors.red);
    } finally {
      if (mounted) setState(() => _fetchingGlobal = false);
    }
  }

  void _toggleAutoUpdate() {
    if (_autoUpdate) {
      _autoUpdateTimer?.cancel();
      _autoUpdateTimer = null;
      setState(() => _autoUpdate = false);
    } else {
      setState(() => _autoUpdate = true);
      _fetchGlobalPrice(isSilent: true);
      _autoUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _fetchGlobalPrice(isSilent: true);
      });
    }
  }

  void _onExchangeRateManualChange(String val) {
    final er = double.tryParse(val);
    if (er != null && er > 0) {
      setState(() {
        _exchangeRate = er;
      });
      _savePrefs();
      if (_globalPrice != null) {
         final double pricePerGramUsd = _globalPrice! / 31.1034768;
         final double pricePerGramIqd = pricePerGramUsd * _exchangeRate;
         setState(() {
           _basePriceController.text = pricePerGramIqd.round().toString();
           _calculatePrices(pricePerGramIqd);
         });
      }
    }
  }

  Future<void> _savePrices() async {
    final basePrice = double.tryParse(_basePriceController.text) ?? 0.0;
    if (basePrice <= 0) return;

    setState(() => _isSaving = true);
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);
    final success = await goldProvider.updatePrices(basePrice, _price21k, _price18k);

    setState(() => _isSaving = false);
    if (success) {
      _showSnackbar('تم تحديث أسعار الذهب بنجاح', LuxuryTheme.emerald600);
      _loadPrices();
    } else {
      _showSnackbar(goldProvider.error ?? 'فشل تحديث أسعار الذهب', Colors.red);
    }
  }

  void _showSnackbar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    num parsedValue = 0;
    if (value != null) {
      if (value is num) {
        parsedValue = value;
      } else if (value is String) {
        parsedValue = double.tryParse(value) ?? 0;
      }
    }
    return intl.NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(parsedValue).trim();
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.parse(d).toLocal();
    return intl.DateFormat.yMMMd('ar').add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final goldProvider = Provider.of<GoldProvider>(context);
    
    double priceChange = 0;
    double percentChange = 0;
    if (_globalPrice != null && _openPrice != null) {
       priceChange = _globalPrice! - _openPrice!;
       if (_openPrice! != 0) {
         percentChange = (priceChange / _openPrice!) * 100;
       }
    }
    
    final bool isUp = priceChange > 0;
    final bool isDown = priceChange < 0;
    final Color trendColor = isUp ? LuxuryTheme.emerald600 : (isDown ? Colors.red : LuxuryTheme.gold);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تحديث أسعار الذهب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPrices,
            )
          ],
        ),
        body: goldProvider.isLoading && goldProvider.history.isEmpty
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Global Market Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 16,
                                decoration: BoxDecoration(color: trendColor, borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تعديل البورصة',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
                                ),
                              ),
                              if (_autoUpdate)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: trendColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: trendColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 2)
                                    ]
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.public, size: 16, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('XAUUSD', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: LuxuryTheme.slate900)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _globalPrice != null 
                                      ? intl.NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(_globalPrice)
                                      : '---',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 32, color: LuxuryTheme.slate900, letterSpacing: -1),
                                  ),
                                  if (_globalPrice != null)
                                    Row(
                                      children: [
                                        Icon(isUp ? Icons.arrow_upward : (isDown ? Icons.arrow_downward : Icons.remove), size: 12, color: trendColor),
                                        Text(
                                          '${isUp ? '+' : ''}${percentChange.toStringAsFixed(2)}% (${priceChange.abs().toStringAsFixed(2)})',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: trendColor),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _toggleAutoUpdate,
                                    icon: Icon(_autoUpdate ? Icons.pause_circle_filled : Icons.play_circle_fill),
                                    color: _autoUpdate ? trendColor : LuxuryTheme.slate400,
                                    iconSize: 32,
                                  ),
                                  IconButton(
                                    onPressed: (_fetchingGlobal || _exchangeRate <= 0) ? null : () => _fetchGlobalPrice(isSilent: false),
                                    icon: _fetchingGlobal 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.refresh),
                                    color: LuxuryTheme.slate900,
                                    style: IconButton.styleFrom(backgroundColor: LuxuryTheme.slate50),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'سعر الصرف (IQD): ',
                                          style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: LuxuryTheme.slate400),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'تلقائي ',
                                          style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: LuxuryTheme.slate400),
                                        ),
                                        Switch(
                                          value: _autoFetchExchangeRate,
                                          activeColor: LuxuryTheme.gold,
                                          onChanged: (v) {
                                            setState(() => _autoFetchExchangeRate = v);
                                            _savePrefs();
                                            if (v) _fetchGlobalPrice(isSilent: true);
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 40,
                                      child: TextField(
                                        controller: _exchangeRateController,
                                        keyboardType: TextInputType.number,
                                        enabled: !_autoFetchExchangeRate,
                                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900),
                                        decoration: LuxuryTheme.inputDecoration(
                                          hintText: 'سعر الصرف',
                                          prefixIcon: Icons.currency_exchange,
                                        ).copyWith(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        onChanged: _onExchangeRateManualChange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Text(
                            'سعر العيار 24 الأساسي (د.ع / غرام)',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: LuxuryTheme.slate400),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _basePriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: 'أدخل السعر الصافي للجرام...',
                              prefixIcon: Icons.trending_up,
                            ),
                            onChanged: (val) {
                              final p = double.tryParse(val) ?? 0.0;
                              _calculatePrices(p);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '* يتم حساب قيم العيارات الأخرى تلقائياً بناءً على النسبة الذهبية.',
                            style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.emerald600, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),

                          // Secondary Karats display
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: LuxuryTheme.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'عيار 21 الموازي',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatCurrency(_price21k)} د.ع',
                                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: LuxuryTheme.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'عيار 18 الموازي',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatCurrency(_price18k)} د.ع',
                                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _savePrices,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LuxuryTheme.gold,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'تحديث جميع المحطات والرموز',
                                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // History Card
                    Container(
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 16,
                                  decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تاريخ تغيرات الأسعار',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
                                )
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          goldProvider.history.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'لا يوجد سجل أسعار متاح',
                                      style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: goldProvider.history.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final p = goldProvider.history[index];
                                    final p24 = double.tryParse(p['price_24k']?.toString() ?? '0') ?? 0.0;
                                    final p21 = double.tryParse(p['price_21k']?.toString() ?? '0') ?? 0.0;
                                    final date = _formatDate(p['created_at']);
                                    final user = p['updated_by_user']?['name'] ?? 'مدير النظام';

                                    return ListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'عيار 24: ${_formatCurrency(p24)} د.ع',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                          ),
                                          Text(
                                            'عيار 21: ${_formatCurrency(p21)} د.ع',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: LuxuryTheme.slate400),
                                          ),
                                        ],
                                      ),
                                      subtitle: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            date,
                                            style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                          ),
                                          Text(
                                            'تحديث: $user',
                                            style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.goldDark, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
