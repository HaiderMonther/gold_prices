import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../services/gold_provider.dart';
import '../theme/luxury_theme.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});

  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  List<dynamic> _traders = [];
  String? _customerId;
  double _basePricePerGram = 0;
  double _discount = 0;
  double _paidAmount = 0;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _saving = false;

  // Item form
  final _itemNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _craftController = TextEditingController(text: '0');
  int _selectedKarat = 21;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _weightController.dispose();
    _craftController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/customers');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body) as List;
        setState(() {
          _traders = all.where((c) => c['type'] == 'trader' || c['type'] == 'workshop').toList();
          _isLoading = false;
        });
        // Set default price
        final goldProvider = Provider.of<GoldProvider>(context, listen: false);
        if (goldProvider.latestPrice != null) {
          _basePricePerGram = goldProvider.getPriceForKarat(21);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل البيانات', LuxuryTheme.rose600);
    }
  }

  double get _adjustedPricePerGram {
    if (_selectedKarat == 21) return _basePricePerGram;
    return (_basePricePerGram / 21) * _selectedKarat;
  }

  double get _itemSubtotal {
    final w = double.tryParse(_weightController.text) ?? 0;
    final c = double.tryParse(_craftController.text) ?? 0;
    return (w * _adjustedPricePerGram) + c;
  }

  bool get _canAddItem => _itemNameController.text.isNotEmpty && (double.tryParse(_weightController.text) ?? 0) > 0;

  double get _totalGoldValue => _items.fold(0.0, (s, i) => s + (i['weight'] * i['price_per_gram']));
  double get _totalCraftValue => _items.fold(0.0, (s, i) => s + i['craft_price']);
  double get _totalAmount => _items.fold(0.0, (s, i) => s + i['total_price']) - _discount;
  double get _remainingAmount => (_totalAmount - _paidAmount).clamp(0, double.infinity);

  void _addItem() {
    if (!_canAddItem) return;
    setState(() {
      _items.add({
        'item_name': _itemNameController.text,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'karat': _selectedKarat,
        'price_per_gram': _adjustedPricePerGram,
        'craft_price': double.tryParse(_craftController.text) ?? 0,
        'total_price': _itemSubtotal,
      });
      _itemNameController.clear();
      _weightController.clear();
      _craftController.text = '0';
      _selectedKarat = 21;
    });
    _showSnackbar('تمت إضافة القطعة', LuxuryTheme.emerald600);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _submitInvoice() async {
    if (_items.isEmpty || _customerId == null) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/invoices', {
        'type': 'purchase',
        'status': 'completed',
        'customer_id': _customerId,
        'paid_amount': _paidAmount,
        'discount': _discount,
        'notes': 'فاتورة شراء مجوهرات من تاجر',
        'items': _items.map((i) => {
              'item_name': i['item_name'],
              'weight': i['weight'],
              'karat': i['karat'],
              'price_per_gram': i['price_per_gram'],
              'craft_price': i['craft_price'],
            }).toList(),
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackbar('تم إنشاء فاتورة الشراء بنجاح', LuxuryTheme.emerald600);
        if (mounted) Navigator.pop(context, true);
      } else {
        final err = jsonDecode(res.body);
        _showSnackbar(err['message'] ?? 'حدث خطأ', LuxuryTheme.rose600);
      }
    } catch (e) {
      _showSnackbar('خطأ في الاتصال بالخادم', LuxuryTheme.rose600);
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

  void _showSnackbar(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: bg, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Directionality(textDirection: TextDirection.rtl,
          child: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('شراء مصوغات', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Trader Selection
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 6, height: 16, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text('بيانات التاجر', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14)),
                        ]),
                        const SizedBox(height: 16),
                        Text('اختر التاجر / الورشة', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _customerId,
                          decoration: LuxuryTheme.inputDecoration(hintText: 'اختر التاجر...', prefixIcon: Icons.store),
                          items: _traders.map((c) => DropdownMenuItem<String>(
                                value: c['id'], child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                              )).toList(),
                          onChanged: (val) => setState(() => _customerId = val),
                        ),
                        const SizedBox(height: 12),
                        Text('سعر الجرام الأساسي (د.ع)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                        const SizedBox(height: 4),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.indigo),
                          decoration: LuxuryTheme.inputDecoration(hintText: '0', prefixIcon: Icons.trending_up),
                          controller: TextEditingController(text: _basePricePerGram.toStringAsFixed(0)),
                          onChanged: (v) => _basePricePerGram = double.tryParse(v) ?? 0,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Item Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 6, height: 16, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text('القطع المشتراة', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14)),
                        ]),
                        const SizedBox(height: 16),
                        Text('اسم القطعة', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _itemNameController,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                          decoration: LuxuryTheme.inputDecoration(hintText: 'مثال: طقم عيار 21...', prefixIcon: Icons.label_outline),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        // Karat
                        Text('العيار', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [24, 21, 18].map((k) => Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedKarat = k),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _selectedKarat == k ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _selectedKarat == k ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('K$k', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: _selectedKarat == k ? Colors.indigo : LuxuryTheme.slate400)),
                                    ),
                                  ),
                                )).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('الوزن (غرام)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.indigo),
                              decoration: LuxuryTheme.inputDecoration(hintText: '0.00', prefixIcon: Icons.scale_outlined),
                              onChanged: (_) => setState(() {}),
                            ),
                          ])),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('أجور الصياغة', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _craftController, keyboardType: TextInputType.number,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
                              decoration: LuxuryTheme.inputDecoration(hintText: '0', prefixIcon: Icons.build_outlined),
                              onChanged: (_) => setState(() {}),
                            ),
                          ])),
                        ]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _canAddItem ? _addItem : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo, disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text('إضافة إلى الفاتورة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Added Items
                    if (_items.isNotEmpty)
                      Container(
                        decoration: LuxuryTheme.luxuryCard(),
                        child: Column(children: [
                          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                            Container(width: 6, height: 16, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Text('القطع المضافة (${_items.length})', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14)),
                          ])),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                title: Text(item['item_name'], style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13)),
                                subtitle: Text('${item['weight']} غ • K${item['karat']} • أجور: ${_formatCurrency(item['craft_price'])}',
                                    style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text('${_formatCurrency(item['total_price'])} د.ع', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600, size: 20), onPressed: () => _removeItem(index)),
                                ]),
                              );
                            },
                          ),
                        ]),
                      ),
                    const SizedBox(height: 16),

                    // Checkout
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: LuxuryTheme.slate900, borderRadius: BorderRadius.circular(24)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('إتمام العملية', style: GoogleFonts.cairo(color: Colors.indigo.shade200, fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        _checkoutRow('قيمة الذهب', _formatCurrency(_totalGoldValue)),
                        _checkoutRow('إجمالي الأجور', _formatCurrency(_totalCraftValue)),
                        const Divider(color: Colors.white10, height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('المجموع', style: GoogleFonts.cairo(color: Colors.indigo.shade200, fontWeight: FontWeight.w900, fontSize: 13)),
                          Text('${_formatCurrency(_totalAmount)} د.ع', style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('الخصم', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.cairo(color: const Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.w900),
                              decoration: InputDecoration(filled: true, fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LuxuryTheme.gold))),
                              onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                            ),
                          ])),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('المدفوع', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.cairo(color: Colors.indigo.shade200, fontSize: 16, fontWeight: FontWeight.w900),
                              decoration: InputDecoration(filled: true, fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LuxuryTheme.gold))),
                              onChanged: (v) => setState(() => _paidAmount = double.tryParse(v) ?? 0),
                            ),
                          ])),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: LuxuryTheme.rose600.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: LuxuryTheme.rose600.withOpacity(0.2))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('المتبقي (دين)', style: GoogleFonts.cairo(color: const Color(0xFFFB7185), fontSize: 10, fontWeight: FontWeight.w900)),
                            Text('${_formatCurrency(_remainingAmount)} د.ع', style: GoogleFonts.cairo(color: const Color(0xFFFB7185), fontSize: 18, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                          )),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: ElevatedButton(
                            onPressed: _items.isEmpty || _customerId == null || _saving ? null : _submitInvoice,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('تثبيت فاتورة الشراء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                          )),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _checkoutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
        Text('$value د.ع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
