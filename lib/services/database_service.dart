import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/contact.dart';
import '../models/inventory_item.dart';
import '../models/invoice.dart';
import '../models/journal_entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('theeqah_accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. دليل الحسابات (accounts)
    await db.execute('''
      CREATE TABLE accounts (
        account_code TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        account_type TEXT NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
        is_debit_normal INTEGER NOT NULL, -- 1 = Debit, 0 = Credit
        balance REAL NOT NULL DEFAULT 0.0,
        parent_code TEXT,
        level_depth INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (parent_code) REFERENCES accounts (account_code)
      )
    ''');

    // 2. المستودعات (warehouses)
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        location TEXT,
        code TEXT UNIQUE NOT NULL
      )
    ''');

    // 3. الأصناف / المخازن (inventory_items)
    await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sale_price REAL NOT NULL,
        purchase_price REAL NOT NULL,
        quantity_in_stock REAL NOT NULL DEFAULT 0.0,
        warehouse_id INTEGER,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    // 4. حركات المخزن (inventory_movements)
    await db.execute('''
      CREATE TABLE inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL,
        movement_type TEXT NOT NULL, -- ADD (إضافة), DISP (صرف), TRANSFER (تحويل)
        quantity REAL NOT NULL,
        source_warehouse_id INTEGER,
        destination_warehouse_id INTEGER,
        movement_date TEXT NOT NULL,
        reference_doc TEXT,
        FOREIGN KEY (sku) REFERENCES inventory_items (sku),
        FOREIGN KEY (source_warehouse_id) REFERENCES warehouses (id),
        FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    // 5. جهات الاتصال (contacts) - عملاء وموردون
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL, -- CLIENT, SUPPLIER
        phone TEXT,
        email TEXT,
        tax_number TEXT
      )
    ''');

    // 6. الفواتير (invoices)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        contact_id INTEGER,
        invoice_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_type TEXT NOT NULL, -- CASH, BANK, CREDITOR
        warehouse_id INTEGER,
        FOREIGN KEY (contact_id) REFERENCES contacts (id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
      )
    ''');

    // 7. القيود اليومية (journal_entries)
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_date TEXT NOT NULL,
        description TEXT NOT NULL,
        source_document TEXT, -- رقم الفاتورة أو السند
        reference_no TEXT,
        created_at TEXT NOT NULL,
        cost_center_id INTEGER
      )
    ''');

    // 8. سطور القيود اليومية (journal_entry_lines)
    await db.execute('''
      CREATE TABLE journal_entry_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER NOT NULL,
        account_code TEXT NOT NULL,
        debit REAL NOT NULL DEFAULT 0.0,
        credit REAL NOT NULL DEFAULT 0.0,
        description TEXT,
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) ON DELETE CASCADE,
        FOREIGN KEY (account_code) REFERENCES accounts (account_code)
      )
    ''');

    // 9. المستخدمون والصلاحيات (users, roles)
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_name TEXT UNIQUE NOT NULL, -- ADMIN, ACCOUNTANT, AUDITOR
        permissions TEXT NOT NULL -- صلاحيات مفصولة بفواصل
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (role_id) REFERENCES roles (id)
      )
    ''');

    // 10. سجل التدقيق للماليين (audit_logs)
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 11. المرتجعات (returns) - مبيعات ومشتريات
    await db.execute('''
      CREATE TABLE returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_number TEXT UNIQUE NOT NULL,
        invoice_id INTEGER,
        return_type TEXT NOT NULL, -- SALES_RETURN, PURCHASE_RETURN
        return_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        total_amount REAL NOT NULL,
        reason TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id)
      )
    ''');

    // 12. العملات وأسعار الصرف (currencies, exchange_rates)
    await db.execute('''
      CREATE TABLE currencies (
        code TEXT PRIMARY KEY, -- SAR, USD, EUR
        name_ar TEXT NOT NULL,
        symbol TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exchange_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_code TEXT NOT NULL,
        rate REAL NOT NULL, -- سعر الصرف مقابل العملة الأساسية (SAR)
        effective_date TEXT NOT NULL,
        FOREIGN KEY (currency_code) REFERENCES currencies (code)
      )
    ''');

    // 13. مراكز التكلفة والمشاريع (cost_centers)
    await db.execute('''
      CREATE TABLE cost_centers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES cost_centers (id)
      )
    ''');

    // 14. الأصول الثابتة وجداول الإهلاك (fixed_assets, depreciation)
    await db.execute('''
      CREATE TABLE fixed_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_code TEXT UNIQUE NOT NULL,
        name_ar TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        purchase_cost REAL NOT NULL,
        scrap_value REAL NOT NULL DEFAULT 0.0,
        useful_life_years INTEGER NOT NULL,
        depreciation_method TEXT NOT NULL, -- STRAIGHT_LINE, REVENUE_BALANCE
        accumulated_depreciation REAL NOT NULL DEFAULT 0.0,
        current_book_value REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE asset_depreciations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,
        depreciation_year INTEGER NOT NULL,
        depreciation_rate REAL NOT NULL,
        depreciation_amount REAL NOT NULL,
        accumulated_after REAL NOT NULL,
        book_value_after REAL NOT NULL,
        journal_entry_id INTEGER,
        FOREIGN KEY (asset_id) REFERENCES fixed_assets (id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id)
      )
    ''');

    // تغذية أولية لدليل الحسابات حتى يعمل التطبيق بنسقة قياسية فورية
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final List<Map<String, dynamic>> initialAccounts = [
      // 1. الأصول (الأصول المتداولة)
      {'account_code': '1', 'name_ar': 'الأصول', 'name_en': 'Assets', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 150000.0, 'parent_code': null, 'level_depth': 1},
      {'account_code': '11', 'name_ar': 'الأصول المتداولة', 'name_en': 'Current Assets', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 150000.0, 'parent_code': '1', 'level_depth': 2},
      {'account_code': '1101', 'name_ar': 'الصندوق الرئيسي', 'name_en': 'Cash on Hand', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 50000.0, 'parent_code': '11', 'level_depth': 3},
      {'account_code': '1102', 'name_ar': 'بنك الراجحي الرئيسي', 'name_en': 'Al Rajhi Bank', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 85000.0, 'parent_code': '11', 'level_depth': 3},
      {'account_code': '1103', 'name_ar': 'حساب العملاء (مدينون)', 'name_en': 'Accounts Receivable', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 0.0, 'parent_code': '11', 'level_depth': 3},
      {'account_code': '1104', 'name_ar': 'المخزون السلعي (المستودع)', 'name_en': 'Inventory', 'account_type': 'ASSET', 'is_debit_normal': 1, 'balance': 15000.0, 'parent_code': '11', 'level_depth': 3},

      // 2. الخصوم / الالتزامات
      {'account_code': '2', 'name_ar': 'الخصوم / الالتزامات', 'name_en': 'Liabilities', 'account_type': 'LIABILITY', 'is_debit_normal': 0, 'balance': 0.0, 'parent_code': null, 'level_depth': 1},
      {'account_code': '21', 'name_ar': 'الخصوم المتداولة', 'name_en': 'Current Liabilities', 'account_type': 'LIABILITY', 'is_debit_normal': 0, 'balance': 0.0, 'parent_code': '2', 'level_depth': 2},
      {'account_code': '2101', 'name_ar': 'ضريبة القيمة المضافة المستحقة (VAT)', 'name_en': 'VAT Payable', 'account_type': 'LIABILITY', 'is_debit_normal': 0, 'balance': 0.0, 'parent_code': '21', 'level_depth': 3},
      {'account_code': '2102', 'name_ar': 'حساب الموردين (دائنون)', 'name_en': 'Accounts Payable', 'account_type': 'LIABILITY', 'is_debit_normal': 0, 'balance': 0.0, 'parent_code': '21', 'level_depth': 3},

      // 3. حقوق الملكية
      {'account_code': '3101', 'name_ar': 'رأس المال المدفوع', 'name_en': 'Paid-up Capital', 'account_type': 'EQUITY', 'is_debit_normal': 0, 'balance': 150000.0, 'parent_code': null, 'level_depth': 1},

      // 4. الإيرادات
      {'account_code': '4101', 'name_ar': 'إيرادات مبيعات السلع المباشرة', 'name_en': 'Sales Revenue', 'account_type': 'REVENUE', 'is_debit_normal': 0, 'balance': 0.0, 'parent_code': null, 'level_depth': 1},

      // 5. المصروفات
      {'account_code': '5101', 'name_ar': 'تكلفة البضاعة المباعة (COGS)', 'name_en': 'Cost of Goods Sold', 'account_type': 'EXPENSE', 'is_debit_normal': 1, 'balance': 0.0, 'parent_code': null, 'level_depth': 1},
    ];

    final batch = db.batch();
    for (var account in initialAccounts) {
      batch.insert('accounts', account);
    }

    // تغذية أولية لجهات الاتصال
    final List<Map<String, dynamic>> initialContacts = [
      {'id': 1, 'name': 'مؤسسة الرياض التجارية (عميل)', 'type': 'CLIENT', 'phone': '0501234567', 'email': 'riyadh@example.com', 'tax_number': '310123456789013'},
      {'id': 2, 'name': 'شركة الشرقية للتوريد (مورد)', 'type': 'SUPPLIER', 'phone': '0547654321', 'email': 'sharg@example.com', 'tax_number': '311987654321013'},
      {'id': 3, 'name': 'شركة حلول التقنية الرقمية (عميل)', 'type': 'CLIENT', 'phone': '0569876543', 'email': 'tech@example.com', 'tax_number': '310555432109876'},
    ];
    for (var contact in initialContacts) {
      batch.insert('contacts', contact);
    }

    // تغذية أولية للمستودع والمنتجات
    final List<Map<String, dynamic>> initialItems = [
      {'id': 1, 'sku': 'PROD-DELL-I7', 'name': 'لابتوب ديل برو Core i7', 'sale_price': 3500.0, 'purchase_price': 2800.0, 'quantity_in_stock': 15.0, 'warehouse_id': null},
      {'id': 2, 'sku': 'PROD-SAMS-4K', 'name': 'شاشة سامسونج 32 بوصة 4K', 'sale_price': 1800.0, 'purchase_price': 1300.0, 'quantity_in_stock': 25.0, 'warehouse_id': null},
      {'id': 3, 'sku': 'PROD-HP-LSR', 'name': 'طابعة ليزر جيت ملونة HP', 'sale_price': 1200.0, 'purchase_price': 900.0, 'quantity_in_stock': 10.0, 'warehouse_id': null},
    ];
    for (var item in initialItems) {
      batch.insert('inventory_items', item);
    }

    // تغذية أولية للفواتير
    final List<Map<String, dynamic>> initialInvoices = [
      {
        'id': 1,
        'invoice_number': 'INV-2026-001',
        'contact_id': 1,
        'invoice_date': '2026-06-01',
        'subtotal': 3500.0,
        'discount_amount': 0.0,
        'tax_amount': 525.0,
        'total_amount': 4025.0,
        'payment_type': 'CASH',
        'warehouse_id': null
      },
      {
        'id': 2,
        'invoice_number': 'INV-2026-002',
        'contact_id': 3,
        'invoice_date': '2026-06-04',
        'subtotal': 5400.0,
        'discount_amount': 200.0,
        'tax_amount': 780.0,
        'total_amount': 5980.0,
        'payment_type': 'BANK',
        'warehouse_id': null
      },
      {
        'id': 3,
        'invoice_number': 'INV-2026-003',
        'contact_id': 1,
        'invoice_date': '2026-06-08',
        'subtotal': 1800.0,
        'discount_amount': 0.0,
        'tax_amount': 270.0,
        'total_amount': 2070.0,
        'payment_type': 'CREDITOR',
        'warehouse_id': null
      },
      {
        'id': 4,
        'invoice_number': 'INV-2026-004',
        'contact_id': 3,
        'invoice_date': '2026-06-10',
        'subtotal': 1200.0,
        'discount_amount': 50.0,
        'tax_amount': 172.5,
        'total_amount': 1322.5,
        'payment_type': 'CASH',
        'warehouse_id': null
      },
    ];
    for (var invoice in initialInvoices) {
      batch.insert('invoices', invoice);
    }

    await batch.commit(noResult: true);
  }

  // --- دليل الحسابات ---
  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'account_code ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await instance.database;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- جهات الاتصال ---
  Future<List<Contact>> getAllContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  Future<void> insertContact(Contact contact) async {
    final db = await instance.database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- الأصناف السلعية ---
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await instance.database;
    final result = await db.query('inventory_items', orderBy: 'name ASC');
    return result.map((json) => InventoryItem.fromMap(json)).toList();
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await instance.database;
    await db.insert(
      'inventory_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- الفواتير ---
  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final result = await db.query('invoices', orderBy: 'invoice_date DESC, id DESC');
    return result.map((json) => Invoice.fromMap(json)).toList();
  }

  Future<List<Invoice>> getLastInvoices({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query(
      'invoices', 
      orderBy: 'invoice_date DESC, id DESC',
      limit: limit
    );
    return result.map((json) => Invoice.fromMap(json)).toList();
  }

  Future<void> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- القيود اليومية ---
  Future<List<JournalEntry>> getAllJournalEntries() async {
    final db = await instance.database;
    final result = await db.query('journal_entries', orderBy: 'entry_date DESC, id DESC');
    
    List<JournalEntry> entries = [];
    for (var json in result) {
      final id = json['id'] as int;
      final linesResult = await db.query(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [id]
      );
      final lines = linesResult.map((l) => JournalEntryLine.fromMap(l)).toList();
      entries.add(JournalEntry.fromMap(json, lines: lines));
    }
    return entries;
  }

  Future<void> insertJournalEntry(JournalEntry entry) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final entryId = await txn.insert(
        'journal_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var line in entry.lines) {
        await txn.insert(
          'journal_entry_lines',
          line.toMap(entryId: entryId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
