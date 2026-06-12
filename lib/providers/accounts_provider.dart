import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountsProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  List<Account> _accounts = [];
  String? _selectedTypeFilter; // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE or null (ALL)
  String _searchQuery = "";
  bool _isLoading = false;

  // Getters
  List<Account> get accounts => _accounts;
  String? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // Constructor
  AccountsProvider() {
    loadAccounts();
  }

  // Fetch all accounts from database
  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accounts = await _dbService.getAllAccounts();
    } catch (e) {
      debugPrint("Error loading accounts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter accounts according to Type as hierarchy
  List<Account> get filteredAccounts {
    List<Account> temp = _accounts;

    // Filter by type if not null
    if (_selectedTypeFilter != null) {
      // Find all accounts starting with or belonging to that type
      temp = temp.where((acc) => acc.accountType == _selectedTypeFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((acc) =>
          acc.nameAr.contains(_searchQuery) ||
          acc.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          acc.accountCode.contains(_searchQuery)).toList();
    }

    return temp;
  }

  // Change and apply type filters
  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  // Set Search Query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Add Account with automated hierarchical calculations (Parent, Level, Nature)
  Future<bool> addNewAccount({
    required String code,
    required String nameAr,
    required String nameEn,
    required String type,
    required bool isDebitNormal,
    required double initialBalance,
    String? parentCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Determine level/depth automatically if parent is chosen
      int computedLevel = 1;
      if (parentCode != null && parentCode.isNotEmpty) {
        final parent = _accounts.firstWhere(
          (acc) => acc.accountCode == parentCode,
          orElse: () => Account(
            accountCode: parentCode,
            nameAr: "",
            nameEn: "",
            accountType: type,
            isDebitNormal: isDebitNormal,
          ),
        );
        if (parent.nameAr.isNotEmpty) {
          computedLevel = parent.level + 1;
        }
      }

      final newAccount = Account(
        accountCode: code,
        nameAr: nameAr,
        nameEn: nameEn,
        accountType: type,
        isDebitNormal: isDebitNormal,
        balance: initialBalance,
        parentCode: parentCode == "" ? null : parentCode,
        level: computedLevel,
      );

      await _dbService.insertAccount(newAccount);
      await loadAccounts(); // reload the state
      return true;
    } catch (e) {
      debugPrint("Error creating account: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
