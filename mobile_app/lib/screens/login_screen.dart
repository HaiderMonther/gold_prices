import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tenantCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // Tenant branding
  Map<String, dynamic>? _tenantInfo;
  bool _isLoadingTenant = false;
  bool _tenantVerified = false;

  @override
  void dispose() {
    _tenantCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerSettings() {
    final serverController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: LuxuryTheme.slate800,
        title: Text('إعدادات السيرفر', textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('أدخل عنوان API الخاص بالسيرفر.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: serverController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'http://192.168.1.X:3000/api',
              hintStyle: GoogleFonts.cairo(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ApiService.setBaseUrl(serverController.text);
              if (mounted) Navigator.pop(context);
            },
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Future<void> _verifyTenantCode() async {
    if (_tenantCodeController.text.trim().isEmpty) return;
    setState(() { _isLoadingTenant = true; _tenantVerified = false; });
    try {
      final response = await ApiService.get('/auth/tenant/${_tenantCodeController.text.trim()}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tenantInfo = data;
          _tenantVerified = true;
        });
      } else {
        setState(() { _tenantInfo = null; _tenantVerified = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: LuxuryTheme.rose600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Text('كود الشركة غير صحيح أو غير موجود',
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() { _tenantInfo = null; _tenantVerified = false; });
    } finally {
      setState(() => _isLoadingTenant = false);
    }
  }

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _usernameController.text,
      _passwordController.text,
      _tenantCodeController.text.trim(),
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: LuxuryTheme.rose600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(auth.error ?? 'حدث خطأ أثناء تسجيل الدخول',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // Background
            Positioned(top: -100, right: -100,
              child: Container(width: 350, height: 350,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.08)))),
            Positioned(bottom: -100, left: -100,
              child: Container(width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: LuxuryTheme.goldDark.withOpacity(0.12)))),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo - shows tenant logo if available
                    if (_tenantInfo?['logo_url'] != null)
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(_tenantInfo!['logo_url'], fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _defaultLogo()),
                        ),
                      )
                    else
                      _defaultLogo(),
                    
                    const SizedBox(height: 16),
                    Text(
                      _tenantInfo?['name'] ?? 'ذهـبي',
                      style: GoogleFonts.cairo(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()..shader = const LinearGradient(
                          colors: [Color(0xFFB59424), Color(0xFFF3E5AB), Color(0xFFB59424)],
                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 250.0, 70.0)),
                      ),
                    ),
                    Text('THE GOLD HUB MANAGEMENT',
                      style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w900,
                        color: LuxuryTheme.slate400, letterSpacing: 2)),
                    
                    const SizedBox(height: 36),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: LuxuryTheme.luxuryCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تسجيل الدخول',
                            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900)),
                          Text('أدخل كود شركتك ثم بياناتك للدخول',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: LuxuryTheme.slate400)),
                          const SizedBox(height: 24),

                          // ── Tenant Code Field ──
                          Text('كود الشركة',
                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900,
                              color: LuxuryTheme.slate700, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: _tenantCodeController,
                                textDirection: TextDirection.ltr,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _verifyTenantCode(),
                                decoration: LuxuryTheme.inputDecoration(
                                  hintText: 'أدخل كود شركتك (مثال: gold123)',
                                  prefixIcon: Icons.business_outlined,
                                  suffixIcon: _tenantVerified
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                ),
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: LuxuryTheme.slate900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoadingTenant ? null : _verifyTenantCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16)),
                                child: _isLoadingTenant
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.search, color: Colors.white),
                              ),
                            ),
                          ]),

                          // Tenant Verified Badge
                          if (_tenantVerified && _tenantInfo != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.2))),
                              child: Row(children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text(_tenantInfo!['name'],
                                  style: GoogleFonts.cairo(color: Colors.green.shade700, fontWeight: FontWeight.w900, fontSize: 13)),
                                const Spacer(),
                                Text('✓ تم التحقق',
                                  style: GoogleFonts.cairo(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ],
                          
                          const SizedBox(height: 20),

                          // ── Username Field ──
                          Text('اسم المستخدم',
                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900,
                              color: LuxuryTheme.slate700, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: 'أدخل اسم المستخدم...', prefixIcon: Icons.person_outline),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: LuxuryTheme.slate900)),
                          const SizedBox(height: 16),

                          // ── Password Field ──
                          Text('كلمة المرور',
                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900,
                              color: LuxuryTheme.slate700, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: LuxuryTheme.inputDecoration(
                              hintText: '••••••••', prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: LuxuryTheme.slate400),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: LuxuryTheme.slate900)),
                          const SizedBox(height: 28),

                          // ── Login Button ──
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                shadowColor: LuxuryTheme.gold.withOpacity(0.3),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: EdgeInsets.zero),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LuxuryTheme.getPrimaryGradient(context),
                                  borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: auth.isLoading
                                    ? const SizedBox(width: 24, height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2.5))
                                    : Text('دخول للنظام',
                                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(onPressed: _showServerSettings,
                        icon: const Icon(Icons.settings_outlined, color: LuxuryTheme.slate400),
                        tooltip: 'إعدادات السيرفر'),
                      const SizedBox(width: 8),
                      Text('LUXURY MANAGEMENT v2.0',
                        style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: LuxuryTheme.slate400)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultLogo() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: LuxuryTheme.getPrimaryGradient(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: LuxuryTheme.gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: const Icon(Icons.diamond_outlined, size: 40, color: Colors.white),
    );
  }
}
