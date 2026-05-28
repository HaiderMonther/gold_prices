import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';
import 'new_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = ''; // empty, 'sale', or 'return'

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/invoices');
      if (response.statusCode == 200) {
        setState(() {
          _invoices = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل الفواتير', Colors.red);
    }
  }

  List<dynamic> get _filteredInvoices {
    return _invoices.where((inv) {
      final matchesSearch = _searchQuery.isEmpty ||
          (inv['invoice_number']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (inv['customer']?['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesType = _filterType.isEmpty || inv['type'] == _filterType;

      return matchesSearch && matchesType;
    }).toList();
  }

  double _getSalesTotal() {
    return _filteredInvoices
        .where((i) => i['type'] == 'sale')
        .fold(0.0, (s, i) => s + (double.tryParse(i['total_amount']?.toString() ?? '0') ?? 0.0));
  }

  double _getPaidTotal() {
    return _filteredInvoices
        .fold(0.0, (s, i) => s + (double.tryParse(i['paid_amount']?.toString() ?? '0') ?? 0.0));
  }

  double _getWeightTotal() {
    return _filteredInvoices.fold(0.0, (s, inv) {
      final items = inv['items'] as List? ?? [];
      final weight = items.fold(0.0, (ss, ii) => ss + (double.tryParse(ii['weight']?.toString() ?? '0') ?? 0.0));
      return s + weight;
    });
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

  void _showInvoiceDetails(dynamic inv) {
    final isSale = inv['type'] == 'sale';
    final items = inv['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل الفاتورة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18, color: LuxuryTheme.slate900),
                        ),
                        Text(
                          inv['invoice_number'] ?? '',
                          style: GoogleFonts.cairo(color: LuxuryTheme.goldDark, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 24),
                
                // Meta info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaDetail('العميل', inv['customer']?['name'] ?? 'نقدي'),
                    _buildMetaDetail('التاريخ', _formatDate(inv['created_at'])),
                    _buildMetaDetail('المسؤول', inv['user']?['name'] ?? '-'),
                  ],
                ),
                const SizedBox(height: 20),

                // Table of items
                Text(
                  'القطع المشتراة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: LuxuryTheme.slate900),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: LuxuryTheme.slate50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final weight = double.tryParse(item['weight']?.toString() ?? '0') ?? 0.0;
                        final price = double.tryParse(item['price_per_gram']?.toString() ?? '0') ?? 0.0;
                        final craft = double.tryParse(item['craft_price']?.toString() ?? '0') ?? 0.0;
                        final total = (weight * price) + craft;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product']?['name'] ?? 'قطعة ذهب',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                  Text(
                                    '${weight.toStringAsFixed(2)} ج • عيار ${item['karat']} • سعر: ${_formatCurrency(price)}',
                                    style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                  ),
                                ],
                              ),
                              Text(
                                '${_formatCurrency(total)} د.ع',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع الإجمالي', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(
                      '${_formatCurrency(double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0)} د.ع',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 20, color: LuxuryTheme.goldDark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Print Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxuryTheme.slate900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: Text(
                      'طباعة الفاتورة',
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    onPressed: () {
                      _showSnackbar('جاري إرسال الفاتورة للطابعة...', LuxuryTheme.emerald600);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'سجل الفواتير',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadInvoices,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: LuxuryTheme.gold,
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewInvoiceScreen()),
            );
            if (res == true) {
              _loadInvoices();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : Column(
                children: [
                  // Quick Summary stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMiniStat('إجمالي المبيعات', '${_formatCurrency(_getSalesTotal())} د.ع', Colors.amber),
                          const SizedBox(width: 8),
                          _buildMiniStat('المبالغ المحصلة', '${_formatCurrency(_getPaidTotal())} د.ع', Colors.green),
                          const SizedBox(width: 8),
                          _buildMiniStat('إجمالي الوزن', '${_getWeightTotal().toStringAsFixed(2)} غرام', Colors.blue),
                        ],
                      ),
                    ),
                  ),

                  // Search and filters
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: 'ابحث برقم الفاتورة أو العميل...',
                              prefixIcon: Icons.search,
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterType,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.filter_list, color: LuxuryTheme.gold),
                          items: [
                            DropdownMenuItem(value: '', child: Text('الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'sale', child: Text('مبيعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'return', child: Text('إرجاع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            setState(() => _filterType = val ?? '');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Invoices List
                  Expanded(
                    child: _filteredInvoices.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد فواتير مطابقة للبحث',
                              style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredInvoices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final inv = _filteredInvoices[index];
                              final isSale = inv['type'] == 'sale';
                              final number = inv['invoice_number'] ?? '';
                              final name = inv['customer']?['name'] ?? 'نقدي';
                              final total = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
                              final date = _formatDate(inv['created_at']);

                              return Container(
                                decoration: LuxuryTheme.luxuryCard(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSale ? LuxuryTheme.emerald50 : LuxuryTheme.rose50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSale ? Icons.shopping_bag_outlined : Icons.assignment_return_outlined,
                                      color: isSale ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'فاتورة ${isSale ? "بيع" : "إرجاع"} #$number',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                      Text(
                                        '${_formatCurrency(total)} د.ع',
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'العميل: $name',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        date,
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showInvoiceDetails(inv),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900)),
        ],
      ),
    );
  }
}
