import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _shopNameController = TextEditingController(text: 'مجوهرات الذهبي');
  final _shopAddressController = TextEditingController(text: 'بغداد - الكاظمية');
  final _shopPhoneController = TextEditingController(text: '07700000000');
  final _receiptFooterController = TextEditingController(text: 'البضاعة المباعة لا ترد ولا تستبدل');
  final _apiUrlController = TextEditingController();
  bool _autoPrint = true;
  bool _soundAlerts = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopPhoneController.dispose();
    _receiptFooterController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopNameController.text = prefs.getString('shop_name') ?? 'مجوهرات الذهبي';
      _shopAddressController.text = prefs.getString('shop_address') ?? 'بغداد - الكاظمية';
      _shopPhoneController.text = prefs.getString('shop_phone') ?? '07700000000';
      _receiptFooterController.text = prefs.getString('receipt_footer') ?? 'البضاعة المباعة لا ترد ولا تستبدل';
      _autoPrint = prefs.getBool('auto_print') ?? true;
      _soundAlerts = prefs.getBool('sound_alerts') ?? true;
      _apiUrlController.text = ApiService.baseUrl;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_name', _shopNameController.text);
      await prefs.setString('shop_address', _shopAddressController.text);
      await prefs.setString('shop_phone', _shopPhoneController.text);
      await prefs.setString('receipt_footer', _receiptFooterController.text);
      await prefs.setBool('auto_print', _autoPrint);
      await prefs.setBool('sound_alerts', _soundAlerts);

      // Save API URL if changed
      if (_apiUrlController.text.isNotEmpty && _apiUrlController.text != ApiService.baseUrl) {
        await ApiService.setBaseUrl(_apiUrlController.text);
      }

      _showSnackbar('تم حفظ الإعدادات بنجاح', LuxuryTheme.emerald600);
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء الحفظ', LuxuryTheme.rose600);
    } finally {
      setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إعدادات النظام', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _saving ? null : _saveSettings,
              child: Text(
                _saving ? 'جاري الحفظ...' : 'حفظ',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: LuxuryTheme.gold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Print Settings
              Container(
                padding: const EdgeInsets.all(20),
                decoration: LuxuryTheme.luxuryCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 16, decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text('إعدادات الطباعة والفواتير', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: LuxuryTheme.gold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _settingField('اسم المحل', _shopNameController, Icons.store, 'مجوهرات الذهبي...'),
                    const SizedBox(height: 16),
                    _settingField('العنوان', _shopAddressController, Icons.location_on_outlined, 'المدينة، الشارع...'),
                    const SizedBox(height: 16),
                    _settingField('رقم الهاتف', _shopPhoneController, Icons.phone_outlined, '07XXXXXXXXX', isLtr: true),
                    const SizedBox(height: 16),
                    _settingField('شعار الفاتورة', _receiptFooterController, Icons.format_quote_outlined, 'البضاعة المباعة لا ترد...'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // General Options
              Container(
                padding: const EdgeInsets.all(20),
                decoration: LuxuryTheme.luxuryCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 16, decoration: BoxDecoration(color: LuxuryTheme.gold, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text('خيارات عامة', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: LuxuryTheme.gold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _toggleSetting(
                      'الطباعة التلقائية',
                      'طباعة الفاتورة تلقائياً عند حفظها',
                      _autoPrint,
                      (v) => setState(() => _autoPrint = v),
                    ),
                    const SizedBox(height: 12),
                    _toggleSetting(
                      'التنبيه بالصوت',
                      'تشغيل نغمة عند إتمام العمليات',
                      _soundAlerts,
                      (v) => setState(() => _soundAlerts = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Settings (Mobile only)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuxuryTheme.slate900,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 16, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text('إعدادات الاتصال', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.blue.shade200)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('رابط API الخادم', style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiUrlController,
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'http://192.168.1.100:3000/api',
                        hintStyle: GoogleFonts.cairo(color: Colors.white24),
                        prefixIcon: const Icon(Icons.link, color: Colors.blue, size: 20),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذا الرابط يستخدم للاتصال بالخادم. تأكد من أن الجهاز على نفس الشبكة.',
                      style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxuryTheme.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _saving ? 'جاري الحفظ...' : 'حفظ جميع الإعدادات',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingField(String label, TextEditingController controller, IconData icon, String hint, {bool isLtr = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: LuxuryTheme.inputDecoration(hintText: hint, prefixIcon: icon),
        ),
      ],
    );
  }

  Widget _toggleSetting(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxuryTheme.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 13, color: LuxuryTheme.slate900)),
                Text(subtitle, style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LuxuryTheme.gold,
          ),
        ],
      ),
    );
  }
}
