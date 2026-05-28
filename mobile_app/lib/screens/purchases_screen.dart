import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<dynamic> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/purchases');
      if (response.statusCode == 200) {
        setState(() {
          _purchases = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل المشتريات', Colors.red);
    }
  }

  double get _totalWeight {
    return _purchases.fold(0.0, (s, p) => s + (double.tryParse(p['weight']?.toString() ?? '0') ?? 0.0));
  }

  double get _totalPaid {
    return _purchases.fold(0.0, (s, p) => s + (double.tryParse(p['paid_amount']?.toString() ?? '0') ?? 0.0));
  }

  void _showAddDialog() {
    final sellerController = TextEditingController();
    final weightController = TextEditingController(text: '0');
    final marketPriceController = TextEditingController(text: '0');
    final paidController = TextEditingController(text: '0');
    String goldType = 'used';
    int karat = 21;
    double eq24 = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateEq24() {
              final w = double.tryParse(weightController.text) ?? 0.0;
              setDialogState(() {
                eq24 = (w * karat) / 24;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'عملية شراء ذهب جديدة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: sellerController,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'اسم البائع / المصدر...', prefixIcon: Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: goldType,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'النوع', prefixIcon: Icons.category_outlined),
                            items: const [
                              DropdownMenuItem(value: 'new', child: Text('ذهب جديد')),
                              DropdownMenuItem(value: 'used', child: Text('مستعمل')),
                              DropdownMenuItem(value: 'scrap', child: Text('كسر')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => goldType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: LuxuryTheme.inputDecoration(hintText: 'الوزن (غرام)', prefixIcon: Icons.scale_outlined),
                            onChanged: (_) => updateEq24(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: karat,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'العيار', prefixIcon: Icons.star_border),
                            items: const [
                              DropdownMenuItem(value: 24, child: Text('عيار 24')),
                              DropdownMenuItem(value: 21, child: Text('عيار 21')),
                              DropdownMenuItem(value: 18, child: Text('عيار 18')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                karat = val;
                                updateEq24();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LuxuryTheme.gold.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المعادل الصافي (عيار 24):',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${eq24.toStringAsFixed(3)} غرام',
                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: LuxuryTheme.goldDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marketPriceController,
                            keyboardType: TextInputType.number,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'سعر السوق اليوم', prefixIcon: Icons.money),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: paidController,
                            keyboardType: TextInputType.number,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'المبلغ المدفوع', prefixIcon: Icons.monetization_on_outlined),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.gold),
                  onPressed: () async {
                    if (sellerController.text.isEmpty || (double.tryParse(weightController.text) ?? 0) <= 0) {
                      _showSnackbar('يرجى ملء جميع الحقول المطلوبة بالقيم الصحيحة', Colors.red);
                      return;
                    }

                    final body = {
                      'seller_name': sellerController.text,
                      'gold_type': goldType,
                      'weight': double.tryParse(weightController.text) ?? 0.0,
                      'karat': karat,
                      'market_price': double.tryParse(marketPriceController.text) ?? 0.0,
                      'paid_amount': double.tryParse(paidController.text) ?? 0.0,
                    };

                    try {
                      final response = await ApiService.post('/purchases', body);
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        _showSnackbar('تم تسجيل عملية الشراء بنجاح', LuxuryTheme.emerald600);
                        _loadPurchases();
                      } else {
                        final err = jsonDecode(response.body);
                        _showSnackbar(err['message'] ?? 'فشل الحفظ', Colors.red);
                      }
                    } catch (e) {
                      _showSnackbar('خطأ في الاتصال بالخادم', Colors.red);
                    }
                  },
                  child: Text(
                    'تثبيت الشراء',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePurchase(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text('هل تريد حذف عملية الشراء هذه؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.rose600),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.delete('/purchases/$id');
        if (res.statusCode == 200) {
          _showSnackbar('تم حذف العملية بنجاح', LuxuryTheme.emerald600);
          _loadPurchases();
        } else {
          _showSnackbar('فشل حذف العملية', Colors.red);
        }
      } catch (e) {
        _showSnackbar('خطأ في الاتصال بالسيرفر', Colors.red);
      }
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
    return intl.DateFormat.yMMMd('ar').format(date);
  }

  String _goldTypeLabel(String t) {
    switch (t) {
      case 'new':
        return 'ذهب جديد';
      case 'used':
        return 'مستعمل';
      case 'scrap':
        return 'كسر / خردة';
      default:
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'شراء الذهب والكسر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPurchases,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: LuxuryTheme.gold,
          onPressed: _showAddDialog,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : Column(
                children: [
                  // Statistics Summary
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: LuxuryTheme.luxuryCard(),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('الوزن الكلي المشترى', '${_totalWeight.toStringAsFixed(2)} جرام'),
                          Container(width: 1, height: 40, color: Colors.black.withOpacity(0.05)),
                          _buildStatColumn('المبالغ المدفوعة', '${_formatCurrency(_totalPaid)} د.ع'),
                        ],
                      ),
                    ),
                  ),

                  // List of purchases
                  Expanded(
                    child: _purchases.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد عمليات شراء مسجلة',
                              style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _purchases.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = _purchases[index];
                              final weight = double.tryParse(p['weight']?.toString() ?? '0') ?? 0.0;
                              final paid = double.tryParse(p['paid_amount']?.toString() ?? '0') ?? 0.0;
                              final date = _formatDate(p['created_at']);

                              return Container(
                                decoration: LuxuryTheme.luxuryCard(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p['seller_name'] ?? '',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      Text(
                                        '${_formatCurrency(paid)} د.ع',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: LuxuryTheme.emerald600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'الوزن: ${weight.toStringAsFixed(2)} غرام (عيار ${p['karat']}) • ${_goldTypeLabel(p['gold_type'])}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        date,
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600),
                                    onPressed: () => _deletePurchase(p['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
        ),
      ],
    );
  }
}
