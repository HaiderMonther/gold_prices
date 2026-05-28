import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _checks = [];
  bool _isLoading = true;
  bool _saving = false;
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadChecks() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/inventory');
      if (res.statusCode == 200) {
        setState(() {
          _checks = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل سجلات الجرد', LuxuryTheme.rose600);
    }
  }

  Future<void> _saveCheck() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showSnackbar('الوزن الفعلي مطلوب', LuxuryTheme.rose600);
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await ApiService.post('/inventory', {
        'actual_weight': weight,
        'notes': _notesController.text,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnackbar('تم تسجيل عملية الجرد بنجاح', LuxuryTheme.emerald600);
        _weightController.clear();
        _notesController.clear();
        Navigator.pop(context);
        _loadChecks();
      } else {
        throw Exception();
      }
    } catch (e) {
      _showSnackbar('حدث خطأ أثناء الحفظ', LuxuryTheme.rose600);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showAddDialog() {
    _weightController.clear();
    _notesController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('عملية جرد جديدة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سيقوم النظام بحساب الوزن الإجمالي الحالي المسجل ومقارنته بالوزن الذي ستدخله.',
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('الوزن الفعلي الحالي (غرام)', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22),
                  decoration: LuxuryTheme.inputDecoration(
                    hintText: '0.000',
                    prefixIcon: Icons.scale_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                Text('ملاحظات الجرد', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: LuxuryTheme.inputDecoration(
                    hintText: 'اكتب أي ملاحظات حول حالة الجرد...',
                    prefixIcon: Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveCheck,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuxuryTheme.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _saving ? 'جاري الحفظ...' : 'تثبيت الجرد',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.parse(d).toLocal();
    return intl.DateFormat.yMMMd('ar').format(date);
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
          title: Text('جرد المخزون', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChecks),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: LuxuryTheme.gold,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('بدء جرد جديد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LuxuryTheme.gold))
            : RefreshIndicator(
                color: LuxuryTheme.gold,
                onRefresh: _loadChecks,
                child: _checks.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, size: 48, color: LuxuryTheme.gold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('لم يتم إجراء أي عمليات جرد', style: GoogleFonts.cairo(color: LuxuryTheme.slate400, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _checks.length,
                        itemBuilder: (context, index) {
                          final c = _checks[index];
                          final systemWeight = double.tryParse(c['system_weight']?.toString() ?? '0') ?? 0;
                          final actualWeight = double.tryParse(c['actual_weight']?.toString() ?? '0') ?? 0;
                          final difference = double.tryParse(c['difference']?.toString() ?? '0') ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: LuxuryTheme.luxuryCard(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(c['created_at']),
                                      style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: difference < 0
                                            ? LuxuryTheme.rose50
                                            : difference > 0
                                                ? LuxuryTheme.emerald50
                                                : LuxuryTheme.slate50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(3)}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: difference < 0
                                              ? LuxuryTheme.rose600
                                              : difference > 0
                                                  ? LuxuryTheme.emerald600
                                                  : LuxuryTheme.slate400,
                                        ),
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
                                          Text('وزن النظام', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                                          Text('${systemWeight.toStringAsFixed(3)} غ', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: LuxuryTheme.slate700)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.compare_arrows, color: LuxuryTheme.slate400, size: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('الوزن الفعلي', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                                          Text('${actualWeight.toStringAsFixed(3)} غ', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: LuxuryTheme.slate900)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (c['notes'] != null && c['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(c['notes'], style: GoogleFonts.cairo(fontSize: 11, color: LuxuryTheme.slate400)),
                                ],
                                if (c['user']?['name'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('المسؤول: ${c['user']['name']}', style: GoogleFonts.cairo(fontSize: 9, color: LuxuryTheme.slate400, fontWeight: FontWeight.w900)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
