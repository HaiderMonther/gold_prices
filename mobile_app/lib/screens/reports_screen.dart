import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;

  // Data
  Map<String, dynamic>? _dailyData;
  Map<String, dynamic>? _inventoryData;
  Map<String, dynamic>? _balanceData;
  Map<String, dynamic>? _profitData;
  Map<String, dynamic>? _debtData;

  String _dailyDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _balanceDateFrom = '';
  String _balanceDateTo = '';

  final _tabs = const [
    Tab(text: 'التداول اليومي'),
    Tab(text: 'الموجود'),
    Tab(text: 'بيع/شراء'),
    Tab(text: 'الأرباح'),
    Tab(text: 'الديون'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrentTab();
    });
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTab() async {
    setState(() => _loading = true);
    try {
      switch (_tabController.index) {
        case 0: await _loadDailyTrading(); break;
        case 1: await _loadInventory(); break;
        case 2: await _loadBalance(); break;
        case 3: await _loadProfit(); break;
        case 4: await _loadDebts(); break;
      }
    } catch (e) {
      _showSnackbar('حدث خطأ في تحميل التقرير', LuxuryTheme.rose600);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDailyTrading() async {
    final res = await ApiService.get('/reports/daily-trading?date=$_dailyDate');
    if (res.statusCode == 200) setState(() => _dailyData = jsonDecode(res.body));
  }

  Future<void> _loadInventory() async {
    final res = await ApiService.get('/reports/inventory-summary');
    if (res.statusCode == 200) setState(() => _inventoryData = jsonDecode(res.body));
  }

  Future<void> _loadBalance() async {
    String url = '/reports/sales-vs-purchases';
    List<String> params = [];
    if (_balanceDateFrom.isNotEmpty) params.add('dateFrom=$_balanceDateFrom');
    if (_balanceDateTo.isNotEmpty) params.add('dateTo=$_balanceDateTo');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final res = await ApiService.get(url);
    if (res.statusCode == 200) setState(() => _balanceData = jsonDecode(res.body));
  }

  Future<void> _loadProfit() async {
    final res = await ApiService.get('/reports/profit');
    if (res.statusCode == 200) setState(() => _profitData = jsonDecode(res.body));
  }

  Future<void> _loadDebts() async {
    final res = await ApiService.get('/reports/debts');
    if (res.statusCode == 200) setState(() => _debtData = jsonDecode(res.body));
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

  String _formatDate(String? d) {
    if (d == null) return '';
    return intl.DateFormat.yMMMd('ar').format(DateTime.parse(d).toLocal());
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

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted = intl.DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isFrom) _balanceDateFrom = formatted; else _balanceDateTo = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('التقارير التحليلية', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
            indicatorColor: LuxuryTheme.gold,
            labelColor: LuxuryTheme.gold,
            unselectedLabelColor: LuxuryTheme.slate400,
            tabs: _tabs,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyTab(),
                  _buildInventoryTab(),
                  _buildBalanceTab(),
                  _buildProfitTab(),
                  _buildDebtsTab(),
                ],
              ),
      ),
    );
  }

  // ============ Daily Trading Tab ============
  Widget _buildDailyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: LuxuryTheme.luxuryCard(),
            child: Row(
              children: [
                Text('التاريخ', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.parse(_dailyDate), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) {
                        _dailyDate = intl.DateFormat('yyyy-MM-dd').format(picked);
                        _loadDailyTrading().then((_) => setState(() => _loading = false));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, size: 16, color: LuxuryTheme.slate400),
                        const SizedBox(width: 8),
                        Text(_dailyDate, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_dailyData != null) ...[
            _reportCard('مبيعات اليوم', '${_formatCurrency(_dailyData!['sales']?['total'] ?? 0)} د.ع',
                '${_dailyData!['sales']?['count'] ?? 0} فاتورة • ${(_dailyData!['sales']?['weight'] ?? 0.0).toStringAsFixed(2)} غرام',
                LuxuryTheme.gold, const Color(0xFFFFF7ED), Icons.shopping_cart),
            const SizedBox(height: 8),
            _reportCard('مشتريات اليوم', '${_formatCurrency(_dailyData!['purchases']?['total'] ?? 0)} د.ع',
                '${_dailyData!['purchases']?['count'] ?? 0} عملية • ${(_dailyData!['purchases']?['weight'] ?? 0.0).toStringAsFixed(2)} غرام',
                Colors.indigo, const Color(0xFFEEF2FF), Icons.shopping_bag),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: LuxuryTheme.slate900, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('صافي النقد', style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
                Text('${_formatCurrency((_dailyData!['netCash'] ?? 0).abs())} د.ع',
                    style: GoogleFonts.cairo(fontSize: 22, color: (_dailyData!['netCash'] ?? 0) >= 0 ? const Color(0xFF34D399) : const Color(0xFFFB7185), fontWeight: FontWeight.w900)),
                Text('مصروفات: ${_formatCurrency(_dailyData!['expenses']?['total'] ?? 0)}',
                    style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ============ Inventory Tab ============
  Widget _buildInventoryTab() {
    if (_inventoryData == null) return const SizedBox();
    final byKarat = (_inventoryData!['byKarat'] as List?) ?? [];
    final totals = _inventoryData!['totals'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: LuxuryTheme.slate900, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إجمالي الخزنة', style: GoogleFonts.cairo(fontSize: 12, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${double.tryParse(totals?['total_weight']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                  style: GoogleFonts.cairo(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900)),
              Text('غرام ذهب متاح', style: GoogleFonts.cairo(fontSize: 12, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
              Text('${totals?['count'] ?? 0} قطعة إجمالي', style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          // By karat
          ...byKarat.map((k) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: LuxuryTheme.luxuryCard(),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black.withOpacity(0.05))),
                      child: Text('K${k['karat']}', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: LuxuryTheme.slate700)),
                    ),
                    const SizedBox(width: 10),
                    Text('${k['count']} قطعة', style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                  ]),
                  Text('${double.tryParse(k['total_weight']?.toString() ?? '0')?.toStringAsFixed(2)} غرام',
                      style: GoogleFonts.cairo(fontSize: 14, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
                ]),
              )),
          if (byKarat.isEmpty)
            Padding(padding: const EdgeInsets.all(32),
                child: Text('لا توجد قطع متاحة', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // ============ Balance Tab ============
  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Date filters
        Container(
          padding: const EdgeInsets.all(12),
          decoration: LuxuryTheme.luxuryCard(),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _pickDate(true),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(12)),
                child: Text(_balanceDateFrom.isEmpty ? 'من تاريخ' : _balanceDateFrom, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold))),
            )),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→')),
            Expanded(child: GestureDetector(
              onTap: () => _pickDate(false),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(12)),
                child: Text(_balanceDateTo.isEmpty ? 'إلى تاريخ' : _balanceDateTo, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold))),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () { setState(() => _loading = true); _loadBalance().then((_) => setState(() => _loading = false)); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                child: Text('تحديث', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: LuxuryTheme.gold))),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (_balanceData != null) ...[
          // Sales
          _balanceSection('المبيعات', LuxuryTheme.emerald600, LuxuryTheme.emerald50, [
            _balanceRow('المبلغ', '${_formatCurrency(_balanceData!['sales']?['totalAmount'] ?? 0)}'),
            _balanceRow('الوزن', '${(_balanceData!['sales']?['totalWeight'] ?? 0.0).toStringAsFixed(2)} غ'),
            _balanceRow('الأجور', '${_formatCurrency(_balanceData!['sales']?['totalCraft'] ?? 0)}'),
            _balanceRow('الفواتير', '${_balanceData!['sales']?['count'] ?? 0}'),
          ]),
          const SizedBox(height: 12),
          // Purchases
          _balanceSection('المشتريات', Colors.indigo, const Color(0xFFEEF2FF), [
            _balanceRow('المبلغ', '${_formatCurrency(_balanceData!['purchases']?['totalAmount'] ?? 0)}'),
            _balanceRow('الوزن', '${(_balanceData!['purchases']?['totalWeight'] ?? 0.0).toStringAsFixed(2)} غ'),
            _balanceRow('العمليات', '${_balanceData!['purchases']?['count'] ?? 0}'),
          ]),
        ],
      ]),
    );
  }

  Widget _balanceSection(String title, Color color, Color bg, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LuxuryTheme.luxuryCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 6, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: rows),
      ]),
    );
  }

  Widget _balanceRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
        Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  // ============ Profit Tab ============
  Widget _buildProfitTab() {
    if (_profitData == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _reportCard('أرباح المصنعية', '${_formatCurrency(_profitData!['craftProfit'] ?? 0)} د.ع', '',
            LuxuryTheme.gold, const Color(0xFFFFF7ED), Icons.monetization_on),
        const SizedBox(height: 8),
        _reportCard('إجمالي المصروفات', '${_formatCurrency(_profitData!['totalExpenses'] ?? 0)} د.ع', '',
            LuxuryTheme.rose600, LuxuryTheme.rose50, Icons.receipt_long),
        const SizedBox(height: 8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: LuxuryTheme.slate900, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('صافي الربح', style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.gold, fontWeight: FontWeight.w900)),
            Text('${_formatCurrency((_profitData!['netProfit'] ?? 0).abs())} د.ع',
                style: GoogleFonts.cairo(fontSize: 24, color: (_profitData!['netProfit'] ?? 0) >= 0 ? const Color(0xFF34D399) : const Color(0xFFFB7185), fontWeight: FontWeight.w900)),
            Text('${_profitData!['invoiceCount'] ?? 0} فاتورة مبيعات', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  // ============ Debts Tab ============
  Widget _buildDebtsTab() {
    if (_debtData == null) return const SizedBox();
    final groups = (_debtData!['groups'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: LuxuryTheme.rose50, borderRadius: BorderRadius.circular(20), border: Border.all(color: LuxuryTheme.rose600.withOpacity(0.2))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: LuxuryTheme.rose600.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.warning_amber_rounded, color: LuxuryTheme.rose600)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إجمالي الديون المتبقية', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
              Text('${_formatCurrency(_debtData!['totalRemaining'] ?? 0)} د.ع',
                  style: GoogleFonts.cairo(fontSize: 20, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
            ])),
            Text('${_debtData!['totalCount'] ?? 0} ذمة', style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(height: 16),
        ...groups.map((group) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: LuxuryTheme.luxuryCard(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text(group['customer']?['name']?.substring(0, 2) ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11, color: LuxuryTheme.gold))),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(group['customer']?['name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text('${(group['debts'] as List?)?.length ?? 0} ذمة مفتوحة', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                  Text('${_formatCurrency(group['remaining'] ?? 0)} د.ع', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.rose600)),
                ]),
                const SizedBox(height: 8),
                ...((group['debts'] as List?) ?? []).map((d) => Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: LuxuryTheme.slate50, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(d['invoice']?['invoice_number'] ?? 'بدون فاتورة', style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.slate700, fontWeight: FontWeight.bold)),
                        Row(children: [
                          Text('${_formatCurrency((double.tryParse(d['amount']?.toString() ?? '0') ?? 0) - (double.tryParse(d['paid_amount']?.toString() ?? '0') ?? 0))}',
                              style: GoogleFonts.cairo(fontSize: 12, color: LuxuryTheme.rose600, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          Text(_formatDate(d['created_at']), style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400)),
                        ]),
                      ]),
                    )),
              ]),
            )),
      ]),
    );
  }

  Widget _reportCard(String title, String value, String sub, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LuxuryTheme.luxuryCard(),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
          Text(value, style: GoogleFonts.cairo(fontSize: 16, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900)),
          if (sub.isNotEmpty) Text(sub, style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }
}
