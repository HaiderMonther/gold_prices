import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/auth_provider.dart';
import 'services/gold_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/luxury_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Arabic
  await initializeDateFormatting('ar', null);
  
  // Initialize Api Service (load saved API Base URL)
  await ApiService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GoldProvider()),
      ],
      child: const GoldApp(),
    ),
  );
}

class GoldApp extends StatefulWidget {
  const GoldApp({super.key});

  @override
  State<GoldApp> createState() => _GoldAppState();
}

class _GoldAppState extends State<GoldApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loadSavedAuth();
    
    // Fetch latest gold prices if authenticated
    if (auth.isAuthenticated) {
      if (mounted) {
        final gold = Provider.of<GoldProvider>(context, listen: false);
        await gold.fetchLatestPrice();
      }
    }

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuxuryTheme.getThemeData(),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: LuxuryTheme.gold),
          ),
        ),
      );
    }

    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'ذهبي - Gold Hub',
      debugShowCheckedModeBanner: false,
      theme: LuxuryTheme.getThemeData(primaryColorHex: auth.tenantPrimaryColor),
      home: auth.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
