import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/invoice.dart';
import '../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  double _totalAssets = 0.0;
  double _totalLiabilities = 0.0;
  double _totalEquity = 0.0;
  double _totalRevenues = 0.0;
  double _totalExpenses = 0.0;
  
  List<Invoice> _lastInvoices = [];
  Map<int, String> _contactNames = {};
  bool _isLoading = false;

  // Getters
  double get totalAssets => _totalAssets;
  double get totalLiabilities => _totalLiabilities;
  double get totalEquity => _totalEquity;
  double get totalRevenues => _totalRevenues;
  double get totalExpenses => _totalExpenses;
  double get netProfitOrLoss => _totalRevenues - _totalExpenses;
  
  List<Invoice> get lastInvoices => _lastInvoices;
  Map<int, String> get contactNames => _contactNames;
  bool get isLoading => _isLoading;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. جلب الحسابات واحتساب المجاميع
      final accounts = await _dbService.getAllAccounts();
      _calculateTotals(accounts);

      // 2. جلب جهات الاتصال وبناء خريطة الأسماء
      final contacts = await _dbService.getAllContacts();
      _contactNames = {for (var c in contacts) if (c.id != null) c.id!: c.name};

      // 3. جلب آخر 5 فواتير
      _lastInvoices = await _dbService.getLastInvoices(limit: 5);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTotals(List<Account> accounts) {
    _totalAssets = 0.0;
    _totalLiabilities = 0.0;
    _totalEquity = 0.0;
    _totalRevenues = 0.0;
    _totalExpenses = 0.0;

    // نقوم باحتساب الأرصدة بناءً على الحسابات الرئيسية من المستوى الأول لتجنب التكرار في الحساب
    final rootAccounts = accounts.where((acc) => acc.parentCode == null).toList();

    for (var root in rootAccounts) {
      double rootBalance = root.balance;
      
      // إذا كان الحساب الرئيسي مسجلاً بصفر ولكن الحسابات الفرعية تحتوي على أرصدة، نقوم باحتساب أرصدة الأبناء
      if (rootBalance == 0.0) {
        rootBalance = _sumChildBalances(root.accountCode, accounts);
      }

      switch (root.accountType) {
        case 'ASSET':
          _totalAssets += rootBalance;
          break;
        case 'LIABILITY':
          _totalLiabilities += rootBalance;
          break;
        case 'EQUITY':
          _totalEquity += rootBalance;
          break;
        case 'REVENUE':
          _totalRevenues += rootBalance;
          break;
        case 'EXPENSE':
          _totalExpenses += rootBalance;
          break;
      }
    }
  }

  // دالة تراجعية (Recursive) لحساب مجموع أرصدة الأوراق (الأبناء النهائيين) لحساب معين
  double _sumChildBalances(String code, List<Account> allAccounts) {
    final children = allAccounts.where((acc) => acc.parentCode == code).toList();
    if (children.isEmpty) {
      final currentAcc = allAccounts.firstWhere(
        (acc) => acc.accountCode == code,
        orElse: () => Account(
          accountCode: code,
          nameAr: '',
          accountType: 'ASSET',
          isDebitNormal: true,
          balance: 0.0,
        ),
      );
      return currentAcc.balance;
    }
    
    double sum = 0.0;
    for (var child in children) {
      sum += _sumChildBalances(child.accountCode, allAccounts);
    }
    return sum;
  }
}
