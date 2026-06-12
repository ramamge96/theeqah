import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounts_provider.dart';
import '../models/account.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({Key? key}) : super(key: key);

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التقارير المالية والقوائم الختامية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primaryContainer,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'ميزان المراجعة'),
              Tab(text: 'قائمة الدخل'),
              Tab(text: 'المركز المالي'),
            ],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Consumer<AccountsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allAccounts = provider.accounts;

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTrialBalance(allAccounts, theme),
                _buildIncomeStatement(allAccounts, theme),
                _buildBalanceSheet(allAccounts, theme),
              ],
            );
          },
        ),
      ),
    );
  }

  // ========== دوال مساعدة مشتركة ==========

  /// جمع أرصدة الحسابات الطرفية (Leaf Accounts) فقط تحت حساب معين
  /// تم الإصلاح: الحسابات العكسية تضرب في -1 لتُطرح من المجموع
  double _sumLeafBalances(String code, List<Account> allAccounts) {
    final children = allAccounts.where((acc) => acc.parentCode == code).toList();
    if (children.isEmpty) {
      // هذا حساب طرفي (ورقة)، نرجع رصيده
      final current = allAccounts.firstWhere(
        (acc) => acc.accountCode == code,
        orElse: () => Account(
          accountCode: code,
          nameAr: '',
          nameEn: '',
          accountType: 'ASSET',
          isDebitNormal: true,
          balance: 0.0,
        ),
      );
      // تم الإصلاح: الحساب العكسي يضرب في -1 ليُطرح تلقائياً
      if (_isContraAccount(current)) {
        return current.balance * -1;
      }
      return current.balance;
    }
    // حساب وسيط، نجمع أرصدة أبنائه
    double sum = 0.0;
    for (var child in children) {
      sum += _sumLeafBalances(child.accountCode, allAccounts);
    }
    return sum;
  }

  /// الحصول على الحسابات الطرفية فقط (Leaf Accounts) التي ليس لها أبناء
  List<Account> _getLeafAccounts(List<Account> allAccounts) {
    return allAccounts.where((acc) {
      return !allAccounts.any((other) => other.parentCode == acc.accountCode);
    }).toList();
  }

  /// تصنيف الحساب: هل هو حساب عكسي (Contra Account)؟
  bool _isContraAccount(Account account) {
    switch (account.accountType) {
      case 'ASSET':
        return !account.isDebitNormal; // أصل عكسي: دائن الطبيعة (مثل مجمع الإهلاك)
      case 'LIABILITY':
        return account.isDebitNormal; // خصم عكسي: مدين الطبيعة
      case 'EQUITY':
        return account.isDebitNormal; // ملكية عكسية: مدين الطبيعة
      case 'REVENUE':
        return account.isDebitNormal; // إيراد عكسي: مدين الطبيعة (مثل مردودات المبيعات)
      case 'EXPENSE':
        return !account.isDebitNormal; // مصروف عكسي: دائن الطبيعة (مثل الخصم المكتسب)
      default:
        return false;
    }
  }

  // ========== 1. ميزان المراجعة ==========
  Widget _buildTrialBalance(List<Account> accounts, ThemeData theme) {
    // نستخدم الحسابات الطرفية فقط لتجنب التكرار المزدوج
    final leafAccounts = _getLeafAccounts(accounts);
    final accountsWithBalances = leafAccounts
        .where((acc) => acc.balance != 0.0)
        .toList();

    double totalDebits = 0.0;
    double totalCredits = 0.0;

    // تم الإصلاح: ميزان المراجعة يعرض كل حساب بطبيعته الأصلية بدون قلب
    for (var acc in accountsWithBalances) {
      if (acc.balance > 0) {
        // رصيد موجب: يتبع الطبيعة الأصلية للحساب
        if (acc.isDebitNormal) {
          totalDebits += acc.balance;
        } else {
          totalCredits += acc.balance;
        }
      } else {
        // رصيد سالب: يظهر في العمود المعاكس لطبيعته
        if (acc.isDebitNormal) {
          totalCredits += acc.balance.abs();
        } else {
          totalDebits += acc.balance.abs();
        }
      }
    }

    final isBalanced = (totalDebits - totalCredits).abs() < 0.01;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // مؤشر التوازن
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBalanced ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBalanced ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.warning,
                  color: isBalanced ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  isBalanced ? 'ميزان المراجعة متوازن' : 'ميزان المراجعة غير متوازن!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBalanced ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTableHeader(theme, 'ميزان المراجعة بالأرصدة'),
          const SizedBox(height: 12),

          // رأس الجدول
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // تم الإصلاح: عرض كل حساب بطبيعته الأصلية
          ...accountsWithBalances.map((acc) {
            double debit = 0.0;
            double credit = 0.0;

            if (acc.balance > 0) {
              // رصيد موجب: يتبع الطبيعة الأصلية
              if (acc.isDebitNormal) {
                debit = acc.balance;
              } else {
                credit = acc.balance;
              }
            } else {
              // رصيد سالب: يظهر في العمود المعاكس
              if (acc.isDebitNormal) {
                credit = acc.balance.abs();
              } else {
                debit = acc.balance.abs();
              }
            }

            return _buildAccountRow(acc, debit, credit, theme);
          }),

          const Divider(height: 24),
          _buildTotalRow('المجاميع', totalDebits, totalCredits, theme, isBold: true),
          const SizedBox(height: 8),
          if (!isBalanced)
            _buildTotalRow('الفرق', (totalDebits - totalCredits).abs(), 0, theme, isBold: false),
        ],
      ),
    );
  }

  // ========== 2. قائمة الدخل ==========
  Widget _buildIncomeStatement(List<Account> accounts, ThemeData theme) {
    // نستخدم الحسابات الطرفية فقط
    final leafAccounts = _getLeafAccounts(accounts);

    // الإيرادات: حسابات REVENUE الطرفية
    final revenueAccounts = leafAccounts
        .where((acc) => acc.accountType == 'REVENUE')
        .toList();
    // المصروفات: حسابات EXPENSE الطرفية
    final expenseAccounts = leafAccounts
        .where((acc) => acc.accountType == 'EXPENSE')
        .toList();

    // حساب الإيرادات مع مراعاة الحسابات العكسية
    double totalRevenue = 0.0;
    for (var acc in revenueAccounts) {
      if (_isContraAccount(acc)) {
        totalRevenue -= acc.balance.abs();
      } else {
        totalRevenue += acc.balance.abs();
      }
    }

    // حساب المصروفات مع مراعاة الحسابات العكسية
    double totalExpenses = 0.0;
    for (var acc in expenseAccounts) {
      if (_isContraAccount(acc)) {
        totalExpenses -= acc.balance.abs();
      } else {
        totalExpenses += acc.balance.abs();
      }
    }

    double netProfit = totalRevenue - totalExpenses;
    bool isProfit = netProfit >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(theme, 'قائمة الدخل (ملخص)'),
          const SizedBox(height: 12),

          // قسم الإيرادات
          const Text('الإيرادات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 8),
          ...revenueAccounts.map((acc) {
            final isContra = _isContraAccount(acc);
            final amount = acc.balance.abs();
            return ListTile(
              title: Text(acc.nameAr),
              trailing: Text(
                '${isContra ? "(" : ""}${amount.toStringAsFixed(2)}${isContra ? ")" : ""} ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isContra ? Colors.red : Colors.green,
                ),
              ),
            );
          }),
          ListTile(
            title: const Text('إجمالي الإيرادات', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${totalRevenue.toStringAsFixed(2)} ر.س',
              style: const TextStyle(fontWeight: FontWeight.extrabold, color: Colors.green),
            ),
          ),
          const Divider(height: 24),

          // قسم المصروفات
          const Text('المصروفات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          const SizedBox(height: 8),
          ...expenseAccounts.map((acc) {
            final isContra = _isContraAccount(acc);
            final amount = acc.balance.abs();
            return ListTile(
              title: Text(acc.nameAr),
              trailing: Text(
                '${isContra ? "(" : ""}${amount.toStringAsFixed(2)}${isContra ? ")" : ""} ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isContra ? Colors.green : Colors.red,
                ),
              ),
            );
          }),
          ListTile(
            title: const Text('إجمالي المصروفات', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '(${totalExpenses.toStringAsFixed(2)}) ر.س',
              style: const TextStyle(fontWeight: FontWeight.extrabold, color: Colors.red),
            ),
          ),
          const Divider(height: 24),

          // صافي الربح / الخسارة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isProfit ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isProfit ? 'صافي الربح' : 'صافي الخسارة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isProfit ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                Text(
                  '${netProfit.abs().toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontWeight: FontWeight.extrabold,
                    fontSize: 18,
                    color: isProfit ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 3. المركز المالي (الميزانية العمومية) ==========
  Widget _buildBalanceSheet(List<Account> accounts, ThemeData theme) {
    // الحسابات الجذرية للأنواع الرئيسية
    final assetRoots = accounts.where((acc) => acc.accountType == 'ASSET' && acc.parentCode == null).toList();
    final liabilityRoots = accounts.where((acc) => acc.accountType == 'LIABILITY' && acc.parentCode == null).toList();
    final equityRoots = accounts.where((acc) => acc.accountType == 'EQUITY' && acc.parentCode == null).toList();
    final revenueRoots = accounts.where((acc) => acc.accountType == 'REVENUE' && acc.parentCode == null).toList();
    final expenseRoots = accounts.where((acc) => acc.accountType == 'EXPENSE' && acc.parentCode == null).toList();

    // تم الإصلاح: _sumLeafBalances الآن تطرح الحسابات العكسية تلقائياً
    double totalAssets = 0.0;
    for (var root in assetRoots) {
      totalAssets += _sumLeafBalances(root.accountCode, accounts);
    }

    double totalLiabilities = 0.0;
    for (var root in liabilityRoots) {
      totalLiabilities += _sumLeafBalances(root.accountCode, accounts);
    }

    double totalEquity = 0.0;
    for (var root in equityRoots) {
      totalEquity += _sumLeafBalances(root.accountCode, accounts);
    }

    double totalRevenue = 0.0;
    for (var root in revenueRoots) {
      totalRevenue += _sumLeafBalances(root.accountCode, accounts);
    }

    double totalExpenses = 0.0;
    for (var root in expenseRoots) {
      totalExpenses += _sumLeafBalances(root.accountCode, accounts);
    }

    // الأصول تُعرض بالقيمة المحاسبية (الموجبة)
    double displayAssets = totalAssets.abs();
    // الخصوم تُعرض موجبة (لكن قيمتها الحقيقية دائنة)
    double displayLiabilities = totalLiabilities.abs();
    // حقوق الملكية موجبة
    double displayEquity = totalEquity.abs();
    // الأرباح المحتجزة = الإيرادات - المصروفات
    double retainedEarnings = totalRevenue - totalExpenses;
    double totalEquityAndRetained = displayEquity + retainedEarnings;
    double totalLiabilitiesAndEquity = displayLiabilities + totalEquityAndRetained;
    bool isBalanced = (displayAssets - totalLiabilitiesAndEquity).abs() < 0.01;

    // الحصول على الحسابات الطرفية للأصول والخصوم للعرض
    final leafAccounts = _getLeafAccounts(accounts);
    final assetLeaves = leafAccounts.where((acc) => acc.accountType == 'ASSET').toList();
    final liabilityLeaves = leafAccounts.where((acc) => acc.accountType == 'LIABILITY').toList();
    final equityLeaves = leafAccounts.where((acc) => acc.accountType == 'EQUITY').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // مؤشر التوازن
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBalanced ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBalanced ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.warning,
                  color: isBalanced ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  isBalanced ? 'الميزانية العمومية متوازنة' : 'الميزانية العمومية غير متوازنة!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBalanced ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTableHeader(theme, 'المركز المالي'),
          const SizedBox(height: 12),

          // الأصول
          const Text('الأصول:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          ...assetLeaves.map((acc) {
            final isContra = _isContraAccount(acc);
            final displayValue = acc.balance.abs();
            return ListTile(
              title: Text(acc.nameAr),
              trailing: Text(
                '${isContra ? "(" : ""}${displayValue.toStringAsFixed(2)}${isContra ? ")" : ""} ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isContra ? Colors.red : Colors.green,
                ),
              ),
            );
          }),
          ListTile(
            title: const Text('إجمالي الأصول', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${displayAssets.toStringAsFixed(2)} ر.س',
              style: TextStyle(fontWeight: FontWeight.extrabold, color: Colors.green[800]),
            ),
          ),
          const Divider(height: 24),

          // الخصوم
          const Text('الخصوم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
          ...liabilityLeaves.map((acc) {
            final displayValue = acc.balance.abs();
            return ListTile(
              title: Text(acc.nameAr),
              trailing: Text(
                '${displayValue.toStringAsFixed(2)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
          ListTile(
            title: const Text('إجمالي الخصوم', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${displayLiabilities.toStringAsFixed(2)} ر.س',
              style: TextStyle(fontWeight: FontWeight.extrabold, color: Colors.red[800]),
            ),
          ),
          const Divider(height: 24),

          // حقوق الملكية
          const Text('حقوق الملكية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
          ...equityLeaves.map((acc) {
            final displayValue = acc.balance.abs();
            return ListTile(
              title: Text(acc.nameAr),
              trailing: Text(
                '${displayValue.toStringAsFixed(2)} ر.س',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
          ListTile(
            title: Text('الأرباح المحتجزة (عن الفترة)', style: TextStyle(color: Colors.blueGrey[700])),
            trailing: Text(
              '${retainedEarnings.toStringAsFixed(2)} ر.س',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('إجمالي حقوق الملكية والأرباح', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${totalEquityAndRetained.toStringAsFixed(2)} ر.س',
              style: TextStyle(fontWeight: FontWeight.extrabold, color: Colors.blueGrey[800]),
            ),
          ),
          const Divider(height: 24),

          // المجموع النهائي
          ListTile(
            tileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
            title: const Text('إجمالي الخصوم وحقوق الملكية', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${totalLiabilitiesAndEquity.toStringAsFixed(2)} ر.س',
              style: TextStyle(fontWeight: FontWeight.extrabold, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ========== دوال عرض مساعدة ==========
  Widget _buildTableHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Icon(Icons.table_chart_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(Account account, double debit, double credit, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              '[${account.accountCode}] ${account.nameAr}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              debit > 0 ? debit.toStringAsFixed(2) : '-',
              style: TextStyle(fontSize: 12, color: Colors.green[700]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              credit > 0 ? credit.toStringAsFixed(2) : '-',
              style: TextStyle(fontSize: 12, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double debit, double credit, ThemeData theme, {required bool isBold}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              debit > 0 ? debit.toStringAsFixed(2) : '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.green[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              credit > 0 ? credit.toStringAsFixed(2) : '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.red[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
