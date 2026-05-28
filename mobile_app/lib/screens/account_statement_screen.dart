import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  List<dynamic> _customers = [];
  String? _selectedCustomerId;
  String _dateFrom = '';
  String _dateTo = '';
  Map<String, dynamic>? _statement;
  bool _loading = false;
  bool _loadingCustomers = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await ApiService.get('/customers');
      if (res.statusCode == 200) {
        setState(() {
          _customers = jsonDecode(res.body);
          _loadingCustomers = false;
        });
      }
    } catch (e) {
      setState(() => _loadingCustomers = false);
    }
  }

  Future<void> _loadStatement() async {
    if (_selectedCustomerId == null) return;
    setState(() {
      _loading = true;
      _statement = null;
    });

    try {
      String url = '/reports/account-statement/$_selectedCustomerId';
      List<String> params = [];
      if (_dateFrom.isNotEmpty) params.add('dateFrom=$_dateFrom');
      if (_dateTo.isNotEmpty) params.add('dateTo=$_dateTo');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await ApiService.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _statement = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('حدث خطأ في تحميل الكشف', LuxuryTheme.rose600);
    }
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

  String _customerTypeLabel(String? type) {
    return {'client': 'عميل', 'trader': 'تاجر', 'workshop': 'ورشة'}[type] ?? 'عميل';
  }

  IconData _entryIcon(String? type) {
    return {
      'sale': Icons.shopping_cart,
      'return': Icons.replay,
      'payment': Icons.payments,
      'transfer_out': Icons.arrow_upward,
      'transfer_in': Icons.arrow_downward,
    }[type] ?? Icons.circle;
  }

  Color _entryColor(String? type) {
    return {
      'sale': LuxuryTheme.gold,
      'return': Colors.indigo,
      'payment': LuxuryTheme.emerald600,
      'transfer_out': LuxuryTheme.rose600,
      'transfer_in': Colors.blue,
    }[type] ?? LuxuryTheme.slate400;
  }

  Color _entryBgColor(String? type) {
    return {
      'sale': const Color(0xFFFFF7ED),
      'return': const Color(0xFFEEF2FF),
      'payment': LuxuryTheme.emerald50,
      'transfer_out': LuxuryTheme.rose50,
      'transfer_in': const Color(0xFFEFF6FF),
    }[type] ?? LuxuryTheme.slate50;
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

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted = intl.DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isFrom) {
          _dateFrom = formatted;
        } else {
          _dateTo = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
        ),
        body: _loadingCustomers
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Filters
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('اختر العميل / التاجر', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: '-- اختر الحساب --',
                              prefixIcon: Icons.person_outline,
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('-- اختر الحساب --', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              ),
                              ..._customers.map((c) => DropdownMenuItem<String>(
                                    value: c['id'],
                                    child: Text(
                                      '${c['name']} ${c['type'] == 'trader' ? '(تاجر)' : c['type'] == 'workshop' ? '(ورشة)' : ''}',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedCustomerId = val),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('من تاريخ', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _pickDate(true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: LuxuryTheme.slate50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: LuxuryTheme.slate400),
                                            const SizedBox(width: 8),
                                            Text(
                                              _dateFrom.isEmpty ? 'اختر' : _dateFrom,
                                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: _dateFrom.isEmpty ? LuxuryTheme.slate400 : LuxuryTheme.slate900),
                                            ),
                                          ],
                                        ),
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
                                    Text('إلى تاريخ', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () => _pickDate(false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: LuxuryTheme.slate50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: LuxuryTheme.slate400),
                                            const SizedBox(width: 8),
                                            Text(
                                              _dateTo.isEmpty ? 'اختر' : _dateTo,
                                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: _dateTo.isEmpty ? LuxuryTheme.slate400 : LuxuryTheme.slate900),
                                            ),
                                          ],
                                        ),
                                      ),
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
                              onPressed: _selectedCustomerId == null || _loading ? null : _loadStatement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LuxuryTheme.gold,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.search, color: Colors.white),
                              label: Text('عرض الكشف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: LuxuryTheme.gold)),
                      ),

                    // Statement Results
                    if (_statement != null && !_loading) ...[
                      // Customer Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.slate900,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person, color: LuxuryTheme.gold, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statement!['customer']?['name'] ?? '',
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                  Text(
                                    _customerTypeLabel(_statement!['customer']?['type']),
                                    style: GoogleFonts.cairo(color: LuxuryTheme.gold, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              'مدين (عليه)',
                              _formatCurrency(_statement!['summary']?['totalDebit'] ?? 0),
                              LuxuryTheme.rose600,
                              LuxuryTheme.rose50,
                              Icons.arrow_upward,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _summaryCard(
                              'دائن (له)',
                              _formatCurrency(_statement!['summary']?['totalCredit'] ?? 0),
                              LuxuryTheme.emerald600,
                              LuxuryTheme.emerald50,
                              Icons.arrow_downward,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Net Balance
                      Builder(builder: (context) {
                        final net = (_statement!['summary']?['netBalance'] ?? 0).toDouble();
                        final isDebit = net > 0;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDebit ? LuxuryTheme.rose50 : LuxuryTheme.emerald50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDebit ? LuxuryTheme.rose600.withOpacity(0.2) : LuxuryTheme.emerald600.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDebit ? LuxuryTheme.rose600.withOpacity(0.1) : LuxuryTheme.emerald600.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.balance, color: isDebit ? LuxuryTheme.rose600 : LuxuryTheme.emerald600, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الرصيد الصافي', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                                    Text(
                                      '${_formatCurrency(net.abs())} د.ع',
                                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: isDebit ? LuxuryTheme.rose600 : LuxuryTheme.emerald600),
                                    ),
                                    Text(
                                      net > 0 ? 'مدين (عليه للمحل)' : net < 0 ? 'دائن (له عند المحل)' : 'لا رصيد',
                                      style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: isDebit ? LuxuryTheme.rose600 : LuxuryTheme.emerald600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Entries List
                      Container(
                        decoration: LuxuryTheme.luxuryCard(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(width: 4, height: 16, decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 8),
                                  Text('حركات الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            if ((_statement!['entries'] as List?)?.isEmpty ?? true)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text('لا توجد حركات مسجلة', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (_statement!['entries'] as List).length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final entry = (_statement!['entries'] as List)[index];
                                  final debit = (entry['debit'] ?? 0).toDouble();
                                  final credit = (entry['credit'] ?? 0).toDouble();
                                  final balance = (entry['balance'] ?? 0).toDouble();

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _entryBgColor(entry['type']),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(_entryIcon(entry['type']), color: _entryColor(entry['type']), size: 18),
                                    ),
                                    title: Text(
                                      entry['description'] ?? '',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                    subtitle: Text(
                                      _formatDate(entry['date']),
                                      style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (debit > 0)
                                          Text('${_formatCurrency(debit)}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: LuxuryTheme.rose600)),
                                        if (credit > 0)
                                          Text('${_formatCurrency(credit)}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: LuxuryTheme.emerald600)),
                                        Text(
                                          '${_formatCurrency(balance.abs())} ${balance > 0 ? 'مدين' : balance < 0 ? 'دائن' : ''}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: balance > 0 ? LuxuryTheme.rose600 : balance < 0 ? LuxuryTheme.emerald600 : LuxuryTheme.slate400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Empty State
                    if (_statement == null && !_loading)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.description_outlined, size: 48, color: LuxuryTheme.gold),
                            ),
                            const SizedBox(height: 16),
                            Text('كشف الحساب', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(
                              'اختر عميلاً أو تاجراً من القائمة أعلاه لعرض كشف حسابه المفصل',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(fontSize: 12, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, Color bg, IconData icon) {
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
                Text('$value د.ع', style: GoogleFonts.cairo(fontSize: 14, color: color, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
