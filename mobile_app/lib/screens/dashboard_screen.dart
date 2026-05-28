import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../services/auth_provider.dart';
import '../services/gold_provider.dart';
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';
import 'login_screen.dart';
import 'gold_prices_screen.dart';
import 'new_invoice_screen.dart';
import 'invoices_screen.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'expenses_screen.dart';
import 'purchases_screen.dart';
import 'users_screen.dart';
import 'purchase_invoice_screen.dart';
import 'inventory_check_screen.dart';
import 'account_statement_screen.dart';
import 'cash_box_screen.dart';
import 'debts_screen.dart';
import 'transfers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentInvoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final goldProvider = Provider.of<GoldProvider>(context, listen: false);
      await goldProvider.fetchLatestPrice();

      final statsRes = await ApiService.get('/reports/dashboard');
      final invoicesRes = await ApiService.get('/invoices');

      if (statsRes.statusCode == 200 && invoicesRes.statusCode == 200) {
        final decodedInvoices = jsonDecode(invoicesRes.body) as List;
        setState(() {
          _stats = jsonDecode(statsRes.body);
          _recentInvoices = decodedInvoices.take(4).toList();
          _isLoading = false;
        });
      } else {
        if (statsRes.statusCode == 401 || invoicesRes.statusCode == 401) {
          _handleUnauthorized();
        } else {
          setState(() {
            _error = 'فشل جلب بيانات لوحة التحكم';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  void _handleUnauthorized() {
    Provider.of<AuthProvider>(context, listen: false).forceLogout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _resetSystem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تصفير النظام', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text(
          'هل أنت متأكد من حذف جميع البيانات؟ لا يمكن التراجع عن هذه العملية.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LuxuryTheme.rose600),
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف الكل', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.post('/reports/reset', {});
        if (res.statusCode == 201 || res.statusCode == 200) {
          _fetchDashboardData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: LuxuryTheme.emerald600,
                content: Text('تم تصفير النظام بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            );
          }
        } else {
          throw Exception();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: LuxuryTheme.rose600,
              content: Text('فشل تصفير النظام', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
            ),
          );
        }
      }
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

  String _formatWeight(dynamic value) {
    if (value == null) return '0.00';
    final parsed = double.tryParse(value.toString()) ?? 0.0;
    return intl.NumberFormat.decimalPattern('ar_IQ').format(parsed);
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.parse(d).toLocal();
    return intl.DateFormat.yMMMd('ar').add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final goldProvider = Provider.of<GoldProvider>(context);

    final todaySalesVal = _stats?['today']?['total'] ?? 0.0;
    final todaySalesCount = _stats?['today']?['count'] ?? 0;
    final profitVal = _stats?['profit']?['total'] ?? 0.0;
    final debtsVal = _stats?['debts']?['total'] ?? 0.0;

    final inventoryList = _stats?['inventory'] as List?;
    final availableRow = inventoryList?.firstWhere(
      (element) => element['status'] == 'available',
      orElse: () => null,
    );
    final availableWeight = availableRow?['total_weight'] ?? '0.00';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'ذهـبي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22, color: LuxuryTheme.slate900),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: LuxuryTheme.slate900),
              onPressed: _fetchDashboardData,
            )
          ],
        ),
        drawer: _buildDrawer(context, auth),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : RefreshIndicator(
                color: Theme.of(context).primaryColor,
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Market Pulse Banner
                      _buildMarketPulseBanner(goldProvider),
                      const SizedBox(height: 20),

                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          _buildStatCard(
                            label: 'مبيعات اليوم',
                            value: '${_formatCurrency(todaySalesVal)} د.ع',
                            subText: '$todaySalesCount فواتير تم إصدارها اليوم',
                            icon: Icons.shopping_cart_outlined,
                            iconBg: Theme.of(context).primaryColor.withOpacity(0.1),
                            iconColor: Theme.of(context).primaryColor,
                          ),
                          _buildStatCard(
                            label: 'أرباح المحل',
                            value: '${_formatCurrency(profitVal)} د.ع',
                            subText: 'إجمالي أرباح المصنعية',
                            icon: Icons.trending_up,
                            iconBg: LuxuryTheme.emerald600.withOpacity(0.1),
                            iconColor: LuxuryTheme.emerald600,
                            trend: 'مباشر',
                          ),
                          _buildStatCard(
                            label: 'إجمالي الوزن',
                            value: '${_formatWeight(availableWeight)} غرام',
                            subText: 'ذهب متاح في الخزنة',
                            icon: Icons.inventory_2_outlined,
                            iconBg: Colors.indigo.withOpacity(0.1),
                            iconColor: Colors.indigo,
                          ),
                          _buildStatCard(
                            label: 'ذمم مدينة',
                            value: '${_formatCurrency(debtsVal)} د.ع',
                            subText: 'بانتظار التحصيل',
                            icon: Icons.account_balance_wallet_outlined,
                            iconBg: LuxuryTheme.rose600.withOpacity(0.1),
                            iconColor: LuxuryTheme.rose600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Market Monitor
                      _buildMarketMonitor(goldProvider),
                      const SizedBox(height: 24),

                      // Recent Invoices
                      _buildRecentInvoicesList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      backgroundColor: LuxuryTheme.slate900,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LuxuryTheme.getPrimaryGradient(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?['name'] ?? 'مستخدم غير معروف',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth.user?['role'] == 'admin' ? 'مدير النظام' : 'محاسب',
                          style: GoogleFonts.cairo(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // List of items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                children: [
                  // === الرئيسية ===
                  _buildDrawerSectionTitle('الرئيسية'),
                  _buildDrawerItem(Icons.dashboard_outlined, 'لوحة التحكم', () => Navigator.pop(context)),
                  _buildDrawerItem(Icons.trending_up, 'أسعار الذهب', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GoldPricesScreen()));
                  }),
                  const SizedBox(height: 8),

                  // === التجارة ===
                  _buildDrawerSectionTitle('التجارة'),
                  _buildDrawerItem(Icons.add_shopping_cart, 'بيع مصوغات', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewInvoiceScreen()));
                  }),
                  _buildDrawerItem(Icons.shopping_bag_outlined, 'شراء مصوغات', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseInvoiceScreen()));
                  }),
                  _buildDrawerItem(Icons.monetization_on_outlined, 'شراء كسر (خردة)', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen()));
                  }),
                  _buildDrawerItem(Icons.inventory_2_outlined, 'المخزون', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
                  }),
                  _buildDrawerItem(Icons.fact_check_outlined, 'الجرد الدوري', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                  }),
                  const SizedBox(height: 8),

                  // === الحسابات ===
                  _buildDrawerSectionTitle('الحسابات'),
                  _buildDrawerItem(Icons.description_outlined, 'كشف الحساب', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountStatementScreen()));
                  }),
                  _buildDrawerItem(Icons.account_balance_wallet_outlined, 'الصندوق اليومي', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBoxScreen()));
                  }),
                  _buildDrawerItem(Icons.receipt_long_outlined, 'الفواتير', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
                  }),
                  _buildDrawerItem(Icons.people_outline, 'العملاء والتجار', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()));
                  }),
                  _buildDrawerItem(Icons.assignment_late_outlined, 'الديون', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()));
                  }),
                  _buildDrawerItem(Icons.swap_horiz, 'الحوالات', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransfersScreen()));
                  }),
                  _buildDrawerItem(Icons.money_off_outlined, 'المصروفات', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
                  }),
                  const SizedBox(height: 8),

                  // === التحليلات ===
                  _buildDrawerSectionTitle('التحليلات'),
                  _buildDrawerItem(Icons.bar_chart, 'التقارير', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                  }),
                  const SizedBox(height: 8),

                  // === الإدارة ===
                  _buildDrawerSectionTitle('الإدارة'),
                  if (auth.isAdmin)
                    _buildDrawerItem(Icons.manage_accounts_outlined, 'الموظفين', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
                    }),
                  _buildDrawerItem(Icons.settings_outlined, 'الإعدادات', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: const Icon(Icons.logout, color: LuxuryTheme.rose600),
                title: Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: GoogleFonts.cairo(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Widget _buildMarketPulseBanner(GoldProvider goldProvider) {
    final hasPrice = goldProvider.latestPrice != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LuxuryTheme.emerald600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.trending_up, color: LuxuryTheme.emerald600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤشر السوق اليوم',
                  style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900),
                ),
                Text(
                  'أسعار الذهب مستقرة حالياً',
                  style: GoogleFonts.cairo(fontSize: 13, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (hasPrice) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'عيار 21',
                  style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${_formatCurrency(goldProvider.getPriceForKarat(21))} د.ع',
                  style: GoogleFonts.cairo(fontSize: 14, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subText,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LuxuryTheme.luxuryCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.emerald50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: GoogleFonts.cairo(fontSize: 8, color: LuxuryTheme.emerald600, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 15, color: LuxuryTheme.slate900, fontWeight: FontWeight.w900),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: GoogleFonts.cairo(fontSize: 8, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMonitor(GoldProvider goldProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LuxuryTheme.slate900, Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أسعار الذهب الأساسية',
                style: GoogleFonts.cairo(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'محدث',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildMarketPriceRow('عيار 24 الأساسي', goldProvider.getPriceForKarat(24)),
          const SizedBox(height: 10),
          _buildMarketPriceRow('عيار 21 الأساسي', goldProvider.getPriceForKarat(21)),
          const SizedBox(height: 10),
          _buildMarketPriceRow('عيار 18 الأساسي', goldProvider.getPriceForKarat(18)),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GoldPricesScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'تعديل الأسعار والمصنعية',
                  style: GoogleFonts.cairo(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_left, color: Theme.of(context).primaryColor, size: 16),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMarketPriceRow(String karatLabel, double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            karatLabel,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_formatCurrency(price)} د.ع',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          )
        ],
      ),
    );
  }

  Widget _buildRecentInvoicesList() {
    return Container(
      decoration: LuxuryTheme.luxuryCard(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'آخر الفواتير',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900),
                    )
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetSystem,
                      child: Text(
                        'تصفير النظام',
                        style: GoogleFonts.cairo(color: LuxuryTheme.rose600, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
                      },
                      child: Text(
                        'عرض الكل',
                        style: GoogleFonts.cairo(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _recentInvoices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'لا توجد فواتير حديثة',
                    style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentInvoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final inv = _recentInvoices[index];
                    final isSale = inv['type'] == 'sale';
                    final customerName = inv['customer']?['name'] ?? 'نقدي';
                    final total = inv['total_amount'] ?? 0.0;
                    final number = inv['invoice_number'] ?? '';
                    final date = _formatDate(inv['created_at']);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSale ? LuxuryTheme.emerald50 : LuxuryTheme.rose50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isSale ? Icons.shopping_bag_outlined : Icons.assignment_return_outlined,
                          color: isSale ? LuxuryTheme.emerald600 : LuxuryTheme.rose600,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'فاتورة ${isSale ? "بيع" : "إرجاع"} #$number',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: LuxuryTheme.slate900),
                      ),
                      subtitle: Text(
                        '$date • العميل: $customerName',
                        style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatCurrency(total)} د.ع',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14, color: LuxuryTheme.slate900),
                          ),
                          Text(
                            'القيمة الإجمالية',
                            style: GoogleFonts.cairo(fontSize: 8, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
