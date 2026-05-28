import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<dynamic> _debts = [];
  bool _isLoading = true;
  bool _showUnpaidOnly = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/debts');
      if (res.statusCode == 200) {
        setState(() {
          _debts = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل الديون', LuxuryTheme.rose600);
    }
  }

  List<dynamic> get _filtered =>
      _debts.where((d) => !_showUnpaidOnly || d['is_paid'] != true).toList();

  double get _totalDebts =>
      _debts.fold(0.0, (s, d) => s + (double.tryParse(d['amount'].toString()) ?? 0));

  double get _totalPaid =>
      _debts.fold(0.0, (s, d) => s + (double.tryParse(d['paid_amount'].toString()) ?? 0));

  double get _totalRemaining => _totalDebts - _totalPaid;

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

  void _showPayDialog(Map<String, dynamic> debt) {
    final remaining = (double.tryParse(debt['amount'].toString()) ?? 0) -
        (double.tryParse(debt['paid_amount'].toString()) ?? 0);
    final controller = TextEditingController(text: remaining.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('تسديد دفعة من الدين',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Customer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.slate50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, color: LuxuryTheme.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العميل المستحق',
                              style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              debt['customer']?['name'] ?? 'غير محدد',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.rose50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('المتبقي', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${_formatCurrency(remaining)}', style: GoogleFonts.cairo(fontSize: 16, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.emerald50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('المدفوع', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.emerald600, fontWeight: FontWeight.w900)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${_formatCurrency(double.tryParse(debt['paid_amount'].toString()) ?? 0)}', style: GoogleFonts.cairo(fontSize: 16, color: LuxuryTheme.emerald600, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('مبلغ التحصيل (د.ع)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22),
                  textAlign: TextAlign.center,
                  decoration: LuxuryTheme.inputDecoration(
                    hintText: '0',
                    prefixIcon: Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxuryTheme.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount <= 0) return;
                Navigator.pop(ctx);
                await _payDebt(debt['id'], amount);
              },
              child: Text('تأكيد السداد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payDebt(String debtId, double amount) async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/debts/$debtId/pay', {'amount': amount});
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackbar('تم تسجيل عملية الدفع بنجاح', LuxuryTheme.emerald600);
        _loadDebts();
      } else {
        throw Exception();
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء معالجة الدفع', LuxuryTheme.rose600);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سجل الديون', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDebts,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : RefreshIndicator(
                color: LuxuryTheme.gold,
                onRefresh: _loadDebts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Filter Buttons
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showUnpaidOnly = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_showUnpaidOnly ? const Color(0xFFFFF7ED) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('الكل',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: !_showUnpaidOnly ? LuxuryTheme.gold : LuxuryTheme.slate400,
                                      )),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showUnpaidOnly = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _showUnpaidOnly ? LuxuryTheme.rose50 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('غير المدفوعة',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: _showUnpaidOnly ? LuxuryTheme.rose600 : LuxuryTheme.slate400,
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('إجمالي الديون', _formatCurrency(_totalDebts), LuxuryTheme.rose600, LuxuryTheme.rose50, Icons.warning_amber_rounded)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('المحصلة', _formatCurrency(_totalPaid), LuxuryTheme.emerald600, LuxuryTheme.emerald50, Icons.check_circle_outline)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.slate900,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('صافي المتبقي', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
                            Text('${_formatCurrency(_totalRemaining)} د.ع',
                                style: GoogleFonts.cairo(fontSize: 20, color: LuxuryTheme.goldLight, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Debts List
                      Container(
                        decoration: LuxuryTheme.luxuryCard(),
                        child: _filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text('لا توجد ديون مسجلة', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final d = _filtered[index];
                                  final amount = double.tryParse(d['amount'].toString()) ?? 0;
                                  final paid = double.tryParse(d['paid_amount'].toString()) ?? 0;
                                  final remaining = amount - paid;
                                  final isPaid = d['is_paid'] == true;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isPaid ? LuxuryTheme.emerald50 : LuxuryTheme.rose50,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
                                        color: isPaid ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                                      ),
                                    ),
                                    title: Text(
                                      d['customer']?['name'] ?? 'غير محدد',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'فاتورة: ${d['invoice']?['invoice_number'] ?? '---'} • ${_formatDate(d['created_at'])}',
                                          style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isPaid ? LuxuryTheme.emerald50 : LuxuryTheme.rose50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isPaid ? 'مدفوع' : 'غير مدفوع',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: isPaid ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_formatCurrency(remaining)} د.ع',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: remaining > 0 ? LuxuryTheme.gold : LuxuryTheme.slate400),
                                        ),
                                        if (!isPaid)
                                          GestureDetector(
                                            onTap: () => _showPayDialog(d),
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: LuxuryTheme.slate900,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text('سداد', style: GoogleFonts.cairo(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, Color bg, IconData icon) {
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
            child: Icon(icon, color: color, size: 20),
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
