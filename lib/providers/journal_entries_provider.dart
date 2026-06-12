import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/database_service.dart';

class JournalEntriesProvider extends ChangeNotifier {
  final _dbService = DatabaseService.instance;

  List<JournalEntry> _journalEntries = [];
  List<Account> _accounts = [];
  Map<String, Account> _accountsMap = {};
  bool _isLoading = false;

  // Getters
  List<JournalEntry> get journalEntries => _journalEntries;
  List<Account> get accounts => _accounts;
  Map<String, Account> get accountsMap => _accountsMap;
  bool get isLoading => _isLoading;

  JournalEntriesProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. جلب القيود المحاسبية
      _journalEntries = await _dbService.getAllJournalEntries();

      // 2. جلب الحسابات لاستخدامها في إدخال القيود اليدوية
      _accounts = await _dbService.getAllAccounts();
      _accountsMap = {for (var acc in _accounts) acc.accountCode: acc};
    } catch (e) {
      debugPrint("Error loading journal entries data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إضافة قيد يدوي جديد
  Future<bool> createManualJournalEntry(
    String date,
    String description,
    String? reference,
    List<JournalEntryLine> lines,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      final newEntry = JournalEntry(
        entryDate: date,
        description: description,
        referenceNo: reference,
        sourceDocument: 'قيد يدوي عام',
        createdAt: now,
        lines: lines,
      );

      await _dbService.insertJournalEntry(newEntry);
      
      // إعادة تحميل البيانات
      await loadAllData();
      return true;
    } catch (e) {
      debugPrint("Error creating manual journal entry: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // الحصول على اسم الحساب بناءً على الرمز
  String getAccountName(String code) {
    return _accountsMap[code]?.nameAr ?? code;
  }
}
