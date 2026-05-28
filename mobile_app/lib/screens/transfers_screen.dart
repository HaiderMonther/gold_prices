import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  List<dynamic> _transfers = [];
  List<dynamic> _customers = [];
  bool _isLoading = true;
  bool _saving = false;

  String? _fromCustomerId;
  String? _toCustomerId;
  String _currency = 'IQD';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tRes = await ApiService.get('/transfers');
      final cRes = await ApiService.get('/customers');
      if (tRes.statusCode == 200 && cRes.statusCode == 200) {
        setState(() {
          _transfers = jsonDecode(tRes.body);
          _customers = jsonDecode(cRes.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل الحوالات', LuxuryTheme.rose600);
    }
  }

  double get _totalAmount =>
      _transfers.fold(0.0, (s, t) => s + (double.tryParse(t['amount'].toString()) ?? 0));

  String _formatCurrency(dynamic value) {
    num parsedValue = 0;
    if (value is num) {
      parsedValue = value;
    } else if (value is String) {
      parsedValue = double.tryParse(value) ?? 0;
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

  void _showAddDialog() {
    _fromCustomerId = null;
    _toCustomerId = null;
    _currency = 'IQD';
    _amountController.clear();
    _descriptionController.clear();

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
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  Text('حوالة جديدة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  // From
                  Text('من (المرسل)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _fromCustomerId,
                    decoration: LuxuryTheme.inputDecoration(hintText: 'المحل (نقدي)', prefixIcon: Icons.person_outline),
                    items: [
                      DropdownMenuItem<String>(value: null, child: Text('المحل (نقدي)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                      ..._customers.map((c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => _fromCustomerId = val),
                  ),
                  const SizedBox(height: 12),
                  // To
                  Text('إلى (المستلم)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _toCustomerId,
                    decoration: LuxuryTheme.inputDecoration(hintText: 'المحل (نقدي)', prefixIcon: Icons.person_outline),
                    items: [
                      DropdownMenuItem<String>(value: null, child: Text('المحل (نقدي)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                      ..._customers.map((c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => _toCustomerId = val),
                  ),
                  const SizedBox(height: 12),
                  // Amount
                  Text('المبلغ', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 20, color: LuxuryTheme.gold),
                    decoration: LuxuryTheme.inputDecoration(hintText: '0', prefixIcon: Icons.payments_outlined),
                  ),
                  const SizedBox(height: 12),
                  // Currency
                  Text('العملة', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _currency = 'IQD'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currency == 'IQD' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _currency == 'IQD' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text('دينار عراقي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: _currency == 'IQD' ? LuxuryTheme.gold : LuxuryTheme.slate400)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _currency = 'USD'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currency == 'USD' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _currency == 'USD' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text('دولار أمريكي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: _currency == 'USD' ? LuxuryTheme.emerald600 : LuxuryTheme.slate400)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text('الوصف', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _descriptionController,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: LuxuryTheme.inputDecoration(hintText: 'وصف الحوالة...', prefixIcon: Icons.notes_outlined),
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
                          onPressed: _saving ? null : () => _saveTransfer(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuxuryTheme.gold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_saving ? 'جاري التنفيذ...' : 'تثبيت الحوالة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
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

  Future<void> _saveTransfer(BuildContext ctx) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackbar('المبلغ مطلوب', LuxuryTheme.rose600);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/transfers', {
        'from_customer_id': _fromCustomerId,
        'to_customer_id': _toCustomerId,
        'amount': amount,
        'currency': _currency,
        'description': _descriptionController.text,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackbar('تم تسجيل الحوالة بنجاح', LuxuryTheme.emerald600);
        if (ctx.mounted) Navigator.pop(ctx);
        _loadData();
      } else {
        throw Exception();
      }
    } catch (e) {
      _showSnackbar('حدث خطأ', LuxuryTheme.rose600);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _deleteTransfer(dynamic transfer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('حذف الحوالة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          content: Text('هل أنت متأكد من حذف هذه الحوالة؟', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.rose600),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.delete('/transfers/${transfer['id']}');
        if (res.statusCode == 200) {
          _showSnackbar('تم الحذف', LuxuryTheme.emerald600);
          _loadData();
        } else {
          throw Exception();
        }
      } catch (e) {
        _showSnackbar('فشلت العملية', LuxuryTheme.rose600);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحوالات', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: LuxuryTheme.gold,
          icon: const Icon(Icons.send, color: Colors.white, size: 20),
          label: Text('حوالة جديدة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : RefreshIndicator(
                color: LuxuryTheme.gold,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _statCard('عدد الحوالات', '${_transfers.length}', Colors.blue, const Color(0xFFEFF6FF), Icons.send),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statCard('إجمالي المبالغ', '${_formatCurrency(_totalAmount)} د.ع', LuxuryTheme.gold, const Color(0xFFFFF7ED), Icons.payments),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Transfers List
                      Container(
                        decoration: LuxuryTheme.luxuryCard(),
                        child: _transfers.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(child: Text('لا توجد حوالات', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold))),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _transfers.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final t = _transfers[index];
                                  return Dismissible(
                                    key: Key(t['id'].toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      color: LuxuryTheme.rose600,
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    onDismissed: (_) => _deleteTransfer(t),
                                    confirmDismiss: (_) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: Text('حذف؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('لا', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.rose600),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text('نعم', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.swap_horiz, color: Colors.blue, size: 22),
                                      ),
                                      title: Text(
                                        '${t['from_customer']?['name'] ?? 'المحل'} → ${t['to_customer']?['name'] ?? 'المحل'}',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (t['description'] != null && t['description'].toString().isNotEmpty)
                                            Text(t['description'], style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                                          Text(
                                            '${_formatDate(t['created_at'])} • ${t['currency'] ?? 'IQD'}',
                                            style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        '${_formatCurrency(double.tryParse(t['amount'].toString()) ?? 0)}',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.gold),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 80),
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
                Text(value, style: GoogleFonts.cairo(fontSize: 13, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
