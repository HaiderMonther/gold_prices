import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../services/gold_provider.dart';
import '../theme/luxury_theme.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _invoiceType = 'sale'; // sale or return
  String? _customerId;
  List<dynamic> _customers = [];
  List<dynamic> _availableProducts = [];
  String? _selectedProductId;

  final _priceController = TextEditingController();
  final _craftController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _paidController = TextEditingController(text: '0');

  int _selectedKarat = 21;
  List<Map<String, dynamic>> _addedItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _craftController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final custRes = await ApiService.get('/customers');
      final prodRes = await ApiService.get('/products?status=available');

      if (custRes.statusCode == 200 && prodRes.statusCode == 200) {
        setState(() {
          _customers = jsonDecode(custRes.body);
          _availableProducts = jsonDecode(prodRes.body);
          _isLoading = false;
        });
        _resetItemForm();
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل البيانات من السيرفر', Colors.red);
    }
  }

  void _resetItemForm() {
    final goldProvider = Provider.of<GoldProvider>(context, listen: false);
    setState(() {
      _selectedProductId = null;
      _weightController.text = '0';
      _selectedKarat = 21;
      _craftController.text = '0';
      _priceController.text = goldProvider.getPriceForKarat(21).toStringAsFixed(0);
    });
  }

  void _onProductSelect(String? prodId) {
    if (prodId == null) return;
    final prod = _availableProducts.firstWhere((x) => x['id'] == prodId, orElse: () => null);
    if (prod != null) {
      final goldProvider = Provider.of<GoldProvider>(context, listen: false);
      setState(() {
        _selectedProductId = prodId;
        _weightController.text = prod['weight']?.toString() ?? '0';
        _selectedKarat = prod['karat'] ?? 21;
        _craftController.text = (prod['craft_price'] ?? 0).toString();
        _priceController.text = goldProvider.getPriceForKarat(_selectedKarat).toStringAsFixed(0);
      });
    }
  }

  double get _itemSubtotal {
    final w = double.tryParse(_weightController.text) ?? 0.0;
    final p = double.tryParse(_priceController.text) ?? 0.0;
    final c = double.tryParse(_craftController.text) ?? 0.0;
    return (w * p) + c;
  }

  bool get _canAddItem => _selectedProductId != null && (double.tryParse(_priceController.text) ?? 0) > 0;

  double get _totalGoldValue => _addedItems.fold(0.0, (s, i) => s + (i['weight'] * i['price_per_gram']));
  double get _totalCraftValue => _addedItems.fold(0.0, (s, i) => s + i['craft_price']);
  double get _totalAmount => _addedItems.fold(0.0, (s, i) => s + i['total_price']);
  double get _changeAmount {
    final paid = double.tryParse(_paidController.text) ?? 0.0;
    return paid > _totalAmount ? paid - _totalAmount : 0.0;
  }

  void _addItem() {
    if (!_canAddItem) return;
    final prod = _availableProducts.firstWhere((x) => x['id'] == _selectedProductId);
    
    setState(() {
      _addedItems.add({
        'product_id': prod['id'],
        'productName': prod['name'],
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'karat': _selectedKarat,
        'price_per_gram': double.tryParse(_priceController.text) ?? 0.0,
        'craft_price': double.tryParse(_craftController.text) ?? 0.0,
        'total_price': _itemSubtotal,
        'rawProduct': prod,
      });

      _availableProducts.removeWhere((x) => x['id'] == prod['id']);
    });
    _resetItemForm();
    _showSnackbar('تمت إضافة القطعة للفاتورة', LuxuryTheme.emerald600);
  }

  void _removeItem(int index) {
    final item = _addedItems[index];
    setState(() {
      _availableProducts.add(item['rawProduct']);
      _addedItems.removeAt(index);
    });
  }

  Future<void> _submitInvoice() async {
    if (_addedItems.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final body = {
        'type': _invoiceType,
        'customer_id': _customerId,
        'paid_amount': double.tryParse(_paidController.text) ?? 0.0,
        'notes': _notesController.text,
        'items': _addedItems.map((i) => {
          'product_id': i['product_id'],
          'weight': i['weight'],
          'karat': i['karat'],
          'price_per_gram': i['price_per_gram'],
          'craft_price': i['craft_price'],
        }).toList(),
      };

      final response = await ApiService.post('/invoices', body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackbar('تم إنشاء الفاتورة بنجاح', LuxuryTheme.emerald600);
        if (mounted) {
          Navigator.pop(context, true); // Go back and refresh dashboard
        }
      } else {
        final err = jsonDecode(response.body);
        _showSnackbar(err['message'] ?? 'حدث خطأ أثناء حفظ الفاتورة', Colors.red);
      }
    } catch (e) {
      _showSnackbar('خطأ في الاتصال بالخادم', Colors.red);
    } finally {
      setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'فاتورة جديدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Customer & Invoice Type
                    _buildIdentitySection(),
                    const SizedBox(height: 16),

                    // Section: Add Product Details
                    _buildProductSelectionSection(),
                    const SizedBox(height: 16),

                    // Section: Added Items
                    if (_addedItems.isNotEmpty) ...[
                      _buildAddedItemsSection(),
                      const SizedBox(height: 16),
                    ],

                    // Section: Checkout Summary & Submission
                    _buildCheckoutSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Container(
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
                decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                'بيانات العميل والعملية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _customerId,
                  decoration: LuxuryTheme.inputDecoration(
                    hintText: 'نقدي / عام',
                    prefixIcon: Icons.person_add_alt_1_outlined,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('نقدي / عام', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                    ..._customers.map((c) => DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _customerId = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _invoiceType = 'sale'),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _invoiceType == 'sale' ? LuxuryTheme.gold : Colors.white,
                      border: Border.all(color: LuxuryTheme.gold.withOpacity(0.3)),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      'بيع ذهب',
                      style: GoogleFonts.cairo(
                        color: _invoiceType == 'sale' ? Colors.white : LuxuryTheme.slate900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _invoiceType = 'return'),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _invoiceType == 'return' ? LuxuryTheme.gold : Colors.white,
                      border: Border.all(color: LuxuryTheme.gold.withOpacity(0.3)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      'إرجاع ذهب',
                      style: GoogleFonts.cairo(
                        color: _invoiceType == 'return' ? Colors.white : LuxuryTheme.slate900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductSelectionSection() {
    return Container(
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
                decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                'تفاصيل قطعة الذهب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
              )
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProductId,
            decoration: LuxuryTheme.inputDecoration(
              hintText: 'ابحث عن قطعة...',
              prefixIcon: Icons.search,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('اختر قطعة...', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
              ..._availableProducts.map((p) => DropdownMenuItem<String>(
                    value: p['id'],
                    child: Text(
                      '${p['name']} | عيار ${p['karat']} | ${p['weight']} غرام',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )),
            ],
            onChanged: _onProductSelect,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العيار', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: LuxuryTheme.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Text(
                        'K$_selectedKarat',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: LuxuryTheme.goldDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الوزن (غرام)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _weightController,
                      readOnly: true,
                      decoration: LuxuryTheme.inputDecoration(hintText: '0.00', prefixIcon: Icons.scale_outlined),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سعر الجرام الحالي (د.ع)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'سعر الجرام', prefixIcon: Icons.money),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15),
                      onChanged: (v) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أجور الصياغة (د.ع)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _craftController,
                      keyboardType: TextInputType.number,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'الأجور', prefixIcon: Icons.settings),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15),
                      onChanged: (v) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _canAddItem ? _addItem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxuryTheme.gold,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة إلى الفاتورة',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddedItemsSection() {
    return Container(
      decoration: LuxuryTheme.luxuryCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 16,
                  decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(
                  'القطع المضافة (${_addedItems.length})',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addedItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _addedItems[index];
              return ListTile(
                title: Text(item['productName'], style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13)),
                subtitle: Text(
                  '${item['weight']} غرام • عيار ${item['karat']} • الجرام: ${_formatCurrency(item['price_per_gram'])} • أجور: ${_formatCurrency(item['craft_price'])}',
                  style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatCurrency(item['total_price'])} د.ع',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: LuxuryTheme.slate900),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600),
                      onPressed: () => _removeItem(index),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuxuryTheme.slate900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إتمام وتثبيت الفاتورة',
            style: GoogleFonts.cairo(color: LuxuryTheme.gold, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          
          // Totals breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('قيمة الذهب الأساسية', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              Text('${_formatCurrency(_totalGoldValue)} د.ع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الأجور والمصنعية', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              Text('${_formatCurrency(_totalCraftValue)} د.ع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع النهائي', style: GoogleFonts.cairo(color: LuxuryTheme.gold, fontSize: 14, fontWeight: FontWeight.w900)),
              Text(
                '${_formatCurrency(_totalAmount)} د.ع',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Paid Amount Input
          Text(
            'المبلغ المدفوع من العميل (د.ع)',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _paidController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: LuxuryTheme.gold),
              ),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          // Remaining Change
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الباقي للعميل / الذمة المالية', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                Text(
                  '${_formatCurrency(_changeAmount)} د.ع',
                  style: GoogleFonts.cairo(color: LuxuryTheme.emerald600, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          TextField(
            controller: _notesController,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'ملاحظات إضافية على الفاتورة...',
              hintStyle: GoogleFonts.cairo(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _addedItems.isEmpty || _isSaving ? null : _submitInvoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxuryTheme.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'تثبيت الفاتورة',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
