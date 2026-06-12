import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Providers
import 'providers/accounts_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/journal_entries_provider.dart';

// Import Screens
import 'screens/dashboard_screen.dart';
import 'screens/chart_of_accounts_screen.dart';
import 'screens/journal_entries_screen.dart';
import 'screens/sales_invoice_screen.dart';
import 'screens/financial_reports_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => JournalEntriesProvider()),
      ],
      child: const TrustAccountingApp(),
    ),
  );
}

class TrustAccountingApp extends StatelessWidget {
  const TrustAccountingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام ثقة المحاسبي المتكامل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58), // الأخضر المحاسبي الأنيق
          primary: const Color(0xFF0F9D58),
          primaryContainer: const Color(0xFFE8F5E9),
          secondary: const Color(0xFF1E88E5),
          background: const Color(0xFFFAFAFA),
        ),
        fontFamily: 'Cairo', // الخط العربي المحاسبي المفضل
        appBarTheme: const AppBarTheme(
          elevation: 1,
          centerTitle: true,
        ),
      ),
      home: const MainNavigationHomeScreen(),
    );
  }
}

class MainNavigationHomeScreen extends StatefulWidget {
  const MainNavigationHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationHomeScreen> createState() => _MainNavigationHomeScreenState();
}

class _MainNavigationHomeScreenState extends State<MainNavigationHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChartOfAccountsScreen(),
    const JournalEntriesScreen(),
    const SalesInvoiceScreen(),
    const FinancialReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, size: 26),
              label: 'لوحة التحكم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_tree_rounded),
              activeIcon: Icon(Icons.account_tree_rounded, size: 26),
              label: 'الدليل المحاسبي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              activeIcon: Icon(Icons.history_edu_rounded, size: 26),
              label: 'القيود اليومية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_shopping_cart_rounded),
              activeIcon: Icon(Icons.add_shopping_cart_rounded, size: 26),
              label: 'فاتورة بيع',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded, size: 26),
              label: 'التقارير المالية',
            ),
          ],
        ),
      ),
    );
  }
}
