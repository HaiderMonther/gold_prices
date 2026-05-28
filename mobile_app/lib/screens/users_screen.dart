import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/api_service.dart';
import '../theme/luxury_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/users');
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('حدث خطأ في تحميل طاقم العمل', Colors.red);
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

  void _showAddOrEditDialog([Map<String, dynamic>? user]) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: isEdit ? user['name'] : '');
    final usernameController = TextEditingController(text: isEdit ? user['username'] : '');
    final passwordController = TextEditingController();
    String role = isEdit ? (user['role'] ?? 'cashier') : 'cashier';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isEdit ? 'تعديل حساب موظف' : 'إضافة موظف جديد',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'الاسم الكامل للموظف...', prefixIcon: Icons.badge_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      enabled: !isEdit,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'اسم المستخدم للدخول...', prefixIcon: Icons.alternate_email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: LuxuryTheme.inputDecoration(
                        hintText: isEdit ? 'كلمة مرور جديدة (اختياري)...' : 'كلمة المرور...',
                        prefixIcon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الدور والصلاحيات الوظيفية',
                      style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: LuxuryTheme.slate400),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: LuxuryTheme.inputDecoration(hintText: 'اختر الدور...', prefixIcon: Icons.admin_panel_settings_outlined),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                        DropdownMenuItem(value: 'accountant', child: Text('محاسب')),
                        DropdownMenuItem(value: 'cashier', child: Text('كاشير / مبيعات')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => role = val);
                      },
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
                    if (nameController.text.isEmpty || usernameController.text.isEmpty) {
                      _showSnackbar('الاسم واسم المستخدم مطلوبان', Colors.red);
                      return;
                    }
                    if (!isEdit && passwordController.text.isEmpty) {
                      _showSnackbar('كلمة المرور مطلوبة للمستخدم الجديد', Colors.red);
                      return;
                    }

                    final Map<String, dynamic> body = {
                      'name': nameController.text,
                      'role': role,
                    };
                    if (!isEdit) {
                      body['username'] = usernameController.text;
                    }
                    if (passwordController.text.isNotEmpty) {
                      body['password'] = passwordController.text;
                    }

                    try {
                      final response = isEdit
                          ? await ApiService.put('/users/${user['id']}', body)
                          : await ApiService.post('/users', body);

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(context);
                        _showSnackbar(isEdit ? 'تم تحديث الحساب' : 'تم إضافة الحساب بنجاح', LuxuryTheme.emerald600);
                        _loadUsers();
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
      },
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> u) async {
    final newStatus = !(u['is_active'] ?? true);
    try {
      final res = await ApiService.put('/users/${u['id']}', {'is_active': newStatus});
      if (res.statusCode == 200) {
        _showSnackbar(newStatus ? 'تم تفعيل حساب الموظف' : 'تم قفل/تعطيل حساب الموظف', LuxuryTheme.emerald600);
        _loadUsers();
      } else {
        _showSnackbar('فشل تعديل حالة الموظف', Colors.red);
      }
    } catch (e) {
      _showSnackbar('خطأ في الاتصال بالخادم', Colors.red);
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    final date = DateTime.parse(d).toLocal();
    return intl.DateFormat.yMMMd('ar').format(date);
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'admin':
        return 'مدير';
      case 'accountant':
        return 'محاسب';
      case 'cashier':
        return 'كاشير';
      default:
        return r;
    }
  }

  Color _roleColor(String r) {
    switch (r) {
      case 'admin':
        return LuxuryTheme.goldDark;
      case 'accountant':
        return Colors.indigo;
      case 'cashier':
        return LuxuryTheme.emerald600;
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
            'إدارة طاقم العمل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
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
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final u = _users[index];
                  final name = u['name'] ?? '';
                  final username = u['username'] ?? '';
                  final role = u['role'] ?? 'cashier';
                  final date = _formatDate(u['created_at']);
                  final isActive = u['is_active'] ?? true;
                  final initials = name.substring(0, name.length == 1 ? 1 : 2);

                  return Container(
                    decoration: LuxuryTheme.luxuryCard(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: LuxuryTheme.gold.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: LuxuryTheme.gold.withOpacity(0.15)),
                                ),
                                child: Text(
                                  initials,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16, color: LuxuryTheme.goldDark),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                    Text(
                                      '@$username',
                                      style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _roleColor(role).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _roleLabel(role),
                                  style: GoogleFonts.cairo(
                                    color: _roleColor(role),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive ? LuxuryTheme.emerald600 : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? 'الحساب نشط' : 'الحساب معطل',
                                    style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'تاريخ الانضمام: $date',
                                    style: GoogleFonts.cairo(fontSize: 10, color: LuxuryTheme.slate400),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showAddOrEditDialog(u),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.lock_open_outlined : Icons.lock_outline,
                                      color: isActive ? Colors.grey : Colors.red,
                                    ),
                                    onPressed: () => _toggleUserStatus(u),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
