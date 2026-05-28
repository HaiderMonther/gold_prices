import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class CashBoxScreen extends StatefulWidget {
  const CashBoxScreen({super.key});

  @override
  State<CashBoxScreen> createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen> {
  Map<String, dynamic>? _dailySummary;
  List<dynamic> _entries = [];
  bool _isLoading = true;
  bool _saving = false;
  late String _selectedDate;
  String _formType = 'deposit';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadDaily();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDaily() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/cash-box/daily?date=$_selectedDate');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _dailySummary = data;
          _entries = data['entries'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _dailySummary = {'balance': 0, 'deposits': 0, 'withdrawals': 0, 'net': 0};
        _entries = [];
        _isLoading = false;
      });
    }
  }

  void _goToday() {
    setState(() {
      _selectedDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    });
    _loadDaily();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = intl.DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadDaily();
    }
  }

  void _showAddDialog() {
    _amountController.clear();
    _descriptionController.clear();
    _formType = 'deposit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('إضافة حركة يدوية', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  // Type selector
                  Text('نوع العملية', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.slate50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _formType = 'deposit'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _formType == 'deposit' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _formType == 'deposit' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text('إيداع (وارد)', style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12,
                                color: _formType == 'deposit' ? LuxuryTheme.emerald600 : LuxuryTheme.slate400,
                              )),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _formType = 'withdrawal'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _formType == 'withdrawal' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _formType == 'withdrawal' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text('سحب (صادر)', style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12,
                                color: _formType == 'withdrawal' ? LuxuryTheme.rose600 : LuxuryTheme.slate400,
                              )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('المبلغ (د.ع)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22),
                    textAlign: TextAlign.center,
                    decoration: LuxuryTheme.inputDecoration(hintText: '0', prefixIcon: Icons.payments_outlined),
                  ),
                  const SizedBox(height: 16),
                  Text('البيان / الوصف', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: LuxuryTheme.inputDecoration(hintText: 'مثال: إيداع رأس مال...', prefixIcon: Icons.notes_outlined),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _saveEntry(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuxuryTheme.gold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _saving ? 'جاري التنفيذ...' : 'تثبيت العملية',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry(BuildContext ctx) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _descriptionController.text.isEmpty) {
      _showSnackbar('المبلغ والبيان مطلوبان', LuxuryTheme.rose600);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/cash-box', {
        'type': _formType,
        'amount': amount,
        'description': _descriptionController.text,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackbar('تم تسجيل العملية بنجاح', LuxuryTheme.emerald600);
        if (ctx.mounted) Navigator.pop(ctx);
        _loadDaily();
      } else {
        throw Exception();
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء الحفظ', LuxuryTheme.rose600);
    } finally {
      setState(() => _saving = false);
    }
  }

  String _formatCurrency(dynamic value) {
    num parsedValue = 0;
    if (value is num) {
      parsedValue = value;
    } else if (value is String) {
      parsedValue = double.tryParse(value) ?? 0;
    }
    return intl.NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(parsedValue).trim();
  }

  String _formatTime(String? d) {
    if (d == null) return '';
    final date = DateTime.parse(d).toLocal();
    return intl.DateFormat.Hm('ar').format(date);
  }

  String _refTypeLabel(String? t) {
    return {
      'sale': 'فاتورة بيع', 'purchase': 'شراء', 'expense': 'مصروف',
      'debt_payment': 'سداد دين', 'transfer': 'حوالة', 'manual': 'يدوي', 'opening_balance': 'رصيد افتتاحي',
    }[t] ?? (t ?? '');
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

  @override
  Widget build(BuildContext context) {
    final balance = (_dailySummary?['balance'] ?? 0).toDouble();
    final deposits = (_dailySummary?['deposits'] ?? 0).toDouble();
    final withdrawals = (_dailySummary?['withdrawals'] ?? 0).toDouble();
    final net = (_dailySummary?['net'] ?? 0).toDouble();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الصندوق اليومي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDaily),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: LuxuryTheme.gold,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('إيداع / سحب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : RefreshIndicator(
                color: LuxuryTheme.gold,
                onRefresh: _loadDaily,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Balance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.slate900,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رصيد الصندوق الحالي', style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('${_formatCurrency(balance)}', style: GoogleFonts.cairo(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900)),
                            Text('د.ع', style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Summary Row
                      Row(
                        children: [
                          Expanded(child: _statCard('وارد اليوم', _formatCurrency(deposits), LuxuryTheme.emerald600, LuxuryTheme.emerald50, Icons.arrow_downward)),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard('صادر اليوم', _formatCurrency(withdrawals), LuxuryTheme.rose600, LuxuryTheme.rose50, Icons.arrow_upward)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _statCard('صافي اليوم', _formatCurrency(net.abs()), net >= 0 ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                          net >= 0 ? LuxuryTheme.emerald50 : LuxuryTheme.rose50, Icons.trending_up),
                      const SizedBox(height: 16),

                      // Date Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: LuxuryTheme.luxuryCard(),
                        child: Row(
                          children: [
                            Text('تاريخ اليوم', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: LuxuryTheme.slate50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: LuxuryTheme.slate400),
                                      const SizedBox(width: 8),
                                      Text(_selectedDate, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _goToday,
                              child: Text('اليوم', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: LuxuryTheme.gold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Entries List
                      Container(
                        decoration: LuxuryTheme.luxuryCard(),
                        child: _entries.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text('لا توجد حركات في هذا اليوم', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _entries.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final e = _entries[index];
                                  final isDeposit = e['type'] == 'deposit';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDeposit ? LuxuryTheme.emerald50 : LuxuryTheme.rose50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isDeposit ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      e['description'] ?? '',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    subtitle: Text(
                                      '${_formatTime(e['created_at'])} • ${_refTypeLabel(e['reference_type'])}',
                                      style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isDeposit ? '+' : '-'}${_formatCurrency((e['amount'] ?? 0).toDouble())}',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w900, fontSize: 13,
                                            color: isDeposit ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                                          ),
                                        ),
                                        Text(
                                          '${_formatCurrency((e['balance_after'] ?? 0).toDouble())}',
                                          style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 80), // space for FAB
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                Text('$value د.ع', style: GoogleFonts.cairo(fontSize: 14, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
