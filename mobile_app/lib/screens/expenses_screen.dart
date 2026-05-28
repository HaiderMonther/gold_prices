import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/expenses');
      if (response.statusCode == 200) {
        setState(() {
          _expenses = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل المصروفات', Colors.red);
    }
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (s, e) => s + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0));
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (var e in _expenses) {
      final cat = e['category']?.toString() ?? 'أخرى';
      final amt = double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0;
      totals[cat] = (totals[cat] ?? 0.0) + amt;
    }
    return totals;
  }

  void _showAddDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'أخرى';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'تسجيل مصروف جديد',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: LuxuryTheme.inputDecoration(hintText: 'وصف المصروف...', prefixIcon: Icons.description_outlined),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: LuxuryTheme.inputDecoration(hintText: 'المبلغ (د.ع)', prefixIcon: Icons.money),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: LuxuryTheme.inputDecoration(hintText: 'الفئة', prefixIcon: Icons.category_outlined),
                          items: const [
                            DropdownMenuItem(value: 'أخرى', child: Text('عام')),
                            DropdownMenuItem(value: 'إيجار', child: Text('إيجار')),
                            DropdownMenuItem(value: 'رواتب', child: Text('رواتب')),
                            DropdownMenuItem(value: 'صيانة', child: Text('صيانة')),
                            DropdownMenuItem(value: 'كهرباء وماء', child: Text('خدمات')),
                            DropdownMenuItem(value: 'تسويق', child: Text('تسويق')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => category = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.gold),
                  onPressed: () async {
                    if (descController.text.isEmpty || amountController.text.isEmpty) {
                      _showSnackbar('يرجى ملء جميع الحقول المطلوبة', Colors.red);
                      return;
                    }

                    final body = {
                      'description': descController.text,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'category': category,
                    };

                    try {
                      final response = await ApiService.post('/expenses', body);
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        _showSnackbar('تم تسجيل المصروف بنجاح', LuxuryTheme.emerald600);
                        _loadExpenses();
                      } else {
                        final err = jsonDecode(response.body);
                        _showSnackbar(err['message'] ?? 'فشل الحفظ', Colors.red);
                      }
                    } catch (e) {
                      _showSnackbar('خطأ في الاتصال بالخادم', Colors.red);
                    }
                  },
                  child: Text(
                    'حفظ',
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

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text('هل تريد حذف هذا المصروف؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
        final res = await ApiService.delete('/expenses/$id');
        if (res.statusCode == 200) {
          _showSnackbar('تم حذف المصروف', LuxuryTheme.emerald600);
          _loadExpenses();
        } else {
          _showSnackbar('فشل حذف المصروف', Colors.red);
        }
      } catch (e) {
        _showSnackbar('خطأ في الاتصال بالخادم', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المصروفات اليومية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadExpenses,
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
                  // Categories list
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Total
                          _buildCatSummaryCard('الإجمالي العام', _totalExpenses, LuxuryTheme.slate900, Colors.white),
                          const SizedBox(width: 8),
                          ..._categoryTotals.entries.map((ent) => Row(
                                children: [
                                  _buildCatSummaryCard(ent.key, ent.value, Colors.white, LuxuryTheme.slate900),
                                  const SizedBox(width: 8),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),

                  // List of expenses
                  Expanded(
                    child: _expenses.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد مصروفات مسجلة حالياً',
                              style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _expenses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final e = _expenses[index];
                              final amount = double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0;
                              final date = _formatDate(e['created_at']);

                              return Container(
                                decoration: LuxuryTheme.luxuryCard(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e['description'] ?? '',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      Text(
                                        '- ${_formatCurrency(amount)} د.ع',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: LuxuryTheme.rose600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          e['category'] ?? 'عام',
                                          style: GoogleFonts.cairo(
                                            color: Colors.indigo,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        date,
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600),
                                    onPressed: () => _deleteExpense(e['id']),
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

  Widget _buildCatSummaryCard(String title, double amount, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 9, color: textCol.withOpacity(0.6), fontWeight: FontWeight.bold),
          ),
          Text(
            '${_formatCurrency(amount)} د.ع',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: textCol),
          ),
        ],
      ),
    );
  }
}
