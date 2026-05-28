import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterKarat = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/products');
      if (response.statusCode == 200) {
        setState(() {
          _products = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ أثناء تحميل المنتجات', Colors.red);
    }
  }

  List<dynamic> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          (p['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (p['barcode']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesKarat = _filterKarat.isEmpty || p['karat']?.toString() == _filterKarat;

      return matchesSearch && matchesKarat;
    }).toList();
  }

  void _showAddOrEditDialog([Map<String, dynamic>? product]) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: isEdit ? product['name'] : '');
    final weightController = TextEditingController(text: isEdit ? product['weight']?.toString() : '');
    final craftController = TextEditingController(text: isEdit ? product['craft_price']?.toString() : '0');
    final barcodeController = TextEditingController(text: isEdit ? product['barcode'] ?? '' : '');
    int karat = isEdit ? (product['karat'] ?? 21) : 21;
    String status = isEdit ? (product['status'] ?? 'available') : 'available';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isEdit ? 'تعديل قطعة ذهب' : 'إضافة قطعة للمخزن',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'اسم القطعة (سوار، خاتم...)', prefixIcon: Icons.title),
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
                              if (val != null) setDialogState(() => karat = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: LuxuryTheme.inputDecoration(hintText: 'الوزن (غرام)', prefixIcon: Icons.scale_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: craftController,
                            keyboardType: TextInputType.number,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'صياغة الغرام', prefixIcon: Icons.settings),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: barcodeController,
                            decoration: LuxuryTheme.inputDecoration(hintText: 'الباركود', prefixIcon: Icons.qr_code),
                          ),
                        ),
                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: LuxuryTheme.inputDecoration(hintText: 'الحالة', prefixIcon: Icons.info_outline),
                        items: const [
                          DropdownMenuItem(value: 'available', child: Text('متاح')),
                          DropdownMenuItem(value: 'sold', child: Text('مباع')),
                          DropdownMenuItem(value: 'reserved', child: Text('محجوز')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => status = val);
                        },
                      ),
                    ],
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
                    if (nameController.text.isEmpty || weightController.text.isEmpty) {
                      _showSnackbar('الاسم والوزن مطلوبان', Colors.red);
                      return;
                    }
                    
                    final body = {
                      'name': nameController.text,
                      'weight': double.tryParse(weightController.text) ?? 0.0,
                      'karat': karat,
                      'craft_price': double.tryParse(craftController.text) ?? 0.0,
                      'barcode': barcodeController.text.isEmpty ? null : barcodeController.text,
                      if (isEdit) 'status': status,
                    };

                    try {
                      final response = isEdit
                          ? await ApiService.put('/products/${product['id']}', body)
                          : await ApiService.post('/products', body);

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        _showSnackbar(isEdit ? 'تم تحديث القطعة' : 'تمت إضافة القطعة', LuxuryTheme.emerald600);
                        _loadProducts();
                      } else {
                        final err = jsonDecode(response.body);
                        _showSnackbar(err['message'] ?? 'فشل الحفظ', Colors.red);
                      }
                    } catch (e) {
                      _showSnackbar('خطأ في الاتصال بالسيرفر', Colors.red);
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

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text('هل تريد حذف هذه القطعة نهائياً من المخزون؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
        final res = await ApiService.delete('/products/$id');
        if (res.statusCode == 200) {
          _showSnackbar('تم حذف القطعة بنجاح', LuxuryTheme.emerald600);
          _loadProducts();
        } else {
          _showSnackbar('فشل حذف القطعة', Colors.red);
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

  String _statusLabel(String s) {
    switch (s) {
      case 'available':
        return 'متاح';
      case 'sold':
        return 'مباع';
      case 'reserved':
        return 'محجوز';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'available':
        return LuxuryTheme.emerald600;
      case 'sold':
        return LuxuryTheme.rose600;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المخزن والمخزون',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadProducts,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: LuxuryTheme.gold,
          onPressed: () => _showAddOrEditDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : Column(
                children: [
                  // Search & Filter
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: 'ابحث بالاسم أو الباركود...',
                              prefixIcon: Icons.search,
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterKarat,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.filter_list, color: LuxuryTheme.gold),
                          items: [
                            DropdownMenuItem(value: '', child: Text('الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: '24', child: Text('عيار 24', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: '21', child: Text('عيار 21', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: '18', child: Text('عيار 18', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            setState(() => _filterKarat = val ?? '');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Products List
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد قطع مطابقة للبحث',
                              style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = _filteredProducts[index];
                              final weight = double.tryParse(p['weight']?.toString() ?? '0') ?? 0.0;
                              final craft = double.tryParse(p['craft_price']?.toString() ?? '0') ?? 0.0;

                              return Container(
                                decoration: LuxuryTheme.luxuryCard(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p['name'] ?? '',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(p['status']).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _statusLabel(p['status']),
                                          style: GoogleFonts.cairo(
                                            color: _statusColor(p['status']),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'الوزن: ${weight.toStringAsFixed(3)} جرام • عيار: ${p['karat']} • صياغة: ${_formatCurrency(craft)} د.ع',
                                    style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showAddOrEditDialog(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600),
                                        onPressed: () => _deleteProduct(p['id']),
                                      ),
                                    ],
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
}
