import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<dynamic> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/customers');
      if (response.statusCode == 200) {
        setState(() {
          _customers = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل العملاء', Colors.red);
    }
  }

  List<dynamic> get _filteredCustomers {
    return _customers.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          (c['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (c['phone']?.toString().contains(_searchQuery) ?? false);
      return matchesSearch;
    }).toList();
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

  void _showAddOrEditDialog([Map<String, dynamic>? customer]) {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: isEdit ? customer['name'] : '');
    final phoneController = TextEditingController(text: isEdit ? customer['phone'] ?? '' : '');
    final addressController = TextEditingController(text: isEdit ? customer['address'] ?? '' : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isEdit ? 'تعديل بيانات العميل' : 'إضافة عميل جديد',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: LuxuryTheme.inputDecoration(hintText: 'الاسم الكامل للعميل...', prefixIcon: Icons.person_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: LuxuryTheme.inputDecoration(hintText: 'رقم الهاتف...', prefixIcon: Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: LuxuryTheme.inputDecoration(hintText: 'العنوان (المحافظة/المنطقة)...', prefixIcon: Icons.map_outlined),
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
                if (nameController.text.isEmpty) {
                  _showSnackbar('اسم العميل مطلوب', Colors.red);
                  return;
                }

                final body = {
                  'name': nameController.text,
                  'phone': phoneController.text.isEmpty ? null : phoneController.text,
                  'address': addressController.text.isEmpty ? null : addressController.text,
                };

                try {
                  final response = isEdit
                      ? await ApiService.put('/customers/${customer['id']}', body)
                      : await ApiService.post('/customers', body);

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    _showSnackbar(isEdit ? 'تم تحديث بيانات العميل' : 'تم إضافة العميل بنجاح', LuxuryTheme.emerald600);
                    _loadCustomers();
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
  }

  Future<void> _deleteCustomer(Map<String, dynamic> c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text('هل تريد حذف العميل "${c['name']}" نهائياً؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
        final res = await ApiService.delete('/customers/${c['id']}');
        if (res.statusCode == 200) {
          _showSnackbar('تم حذف العميل بنجاح', LuxuryTheme.emerald600);
          _loadCustomers();
        } else {
          _showSnackbar('فشل حذف العميل', Colors.red);
        }
      } catch (e) {
        _showSnackbar('خطأ في الاتصال بالسيرفر', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة العملاء',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCustomers,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: LuxuryTheme.gold,
          onPressed: () => _showAddOrEditDialog(),
          child: const Icon(Icons.person_add_alt_1, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : Column(
                children: [
                  // Statistics Summary
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إجمالي عدد العملاء',
                                style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_customers.length} عميل مسجل',
                                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: LuxuryTheme.gold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.people_alt, color: LuxuryTheme.goldDark),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: LuxuryTheme.inputDecoration(
                        hintText: 'ابحث عن عميل بالاسم أو رقم الهاتف...',
                        prefixIcon: Icons.search,
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Customers List
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد عملاء مطابقين للبحث',
                              style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredCustomers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final c = _filteredCustomers[index];
                              final debt = double.tryParse(c['debt_balance']?.toString() ?? '0') ?? 0.0;
                              final nameInitials = c['name']?.toString().substring(0, c['name']?.toString().length == 1 ? 1 : 2) ?? '';

                              return Container(
                                decoration: LuxuryTheme.luxuryCard(),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: LuxuryTheme.gold.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: LuxuryTheme.gold.withOpacity(0.15)),
                                    ),
                                    child: Text(
                                      nameInitials,
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: LuxuryTheme.goldDark),
                                    ),
                                  ),
                                  title: Text(
                                    c['name'] ?? '',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الهاتف: ${c['phone'] ?? "غير محدد"}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                      ),
                                      Text(
                                        'العنوان: ${c['address'] ?? "غير محدد"}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${_formatCurrency(debt)} د.ع',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: debt > 0 ? LuxuryTheme.rose600 : LuxuryTheme.emerald600,
                                            ),
                                          ),
                                          Text(
                                            'الديون المتراكمة',
                                            style: GoogleFonts.cairo(fontSize: 8, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showAddOrEditDialog(c),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: LuxuryTheme.rose600),
                                        onPressed: () => _deleteCustomer(c),
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
