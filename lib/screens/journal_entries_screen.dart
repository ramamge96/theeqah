import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/journal_entries_provider.dart';
import '../models/journal_entry.dart';
import '../models/account.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({Key? key}) : super(key: key);

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  @override
  void initState() {
    super.initState();
    // جلب البيانات عند التحميل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalEntriesProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دفتر القيود المحاسبية والتسويات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<JournalEntriesProvider>().loadAllData();
              },
            ),
          ],
        ),
        body: Consumer<JournalEntriesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.journalEntries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = provider.journalEntries;

            return RefreshIndicator(
              onRefresh: () => provider.loadAllData(),
              child: Column(
                children: [
                  // ترويسة ترحيبية وتوضيحية
                  _buildHeaderInfo(entries.length, theme),
                  
                  // قائمة القيود المحاسبية
                  Expanded(
                    child: entries.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            itemCount: entries.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return _buildJournalEntryCard(entry, provider, theme);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddEntryDialog(context, theme),
          label: const Text('إضافة قيد يدوي', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_task_rounded),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(int count, ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'سجل القيود المزدوجة المتوازنة في النظام',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'جميع المعاملات والقيود التلقائية الناتجة عن الفواتير بالإضافة للقيود اليدوية تظهر هنا.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 72, color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'لا توجد قيود محاسبية مسجلة بعد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بالضغط على "إضافة قيد يدوي" لتسجيل معاملتك المالية الأولى.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة عرض قيد يومية فردي
  Widget _buildJournalEntryCard(JournalEntry entry, JournalEntriesProvider provider, ThemeData theme) {
    // حساب مجموع المبالغ المدينة كشاهد للتوازن
    final double totalDebit = entry.lines.fold(0.0, (sum, line) => sum + line.debit);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: Colors.grey[600],
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.sourceDocument == 'قيد يدوي عام' 
                      ? Icons.handwriting_rounded 
                      : Icons.receipt_long,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المستند: ${entry.sourceDocument ?? "قيد تلقائي"} | التاريخ: ${entry.entryDate}',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${totalDebit.toStringAsFixed(2)} ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.extrabold,
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'متوازن الميزانية',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تفاصيل السطور المزدوجة (القيد المحاسبي)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: theme.colorScheme.secondary),
                      ),
                      if (entry.referenceNo != null && entry.referenceNo!.isNotEmpty)
                        Text(
                          'المرجع: ${entry.referenceNo}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // ترويسة الجدول
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                        Expanded(flex: 2, child: Text('مدين (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.left)),
                        Expanded(flex: 2, child: Text('دائن (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.left)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // أسطر القيد الفردية
                  ...entry.lines.map((line) {
                    final accName = provider.getAccountName(line.accountCode);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('[${line.accountCode}] $accName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                if (line.description != null && line.description!.isNotEmpty)
                                  Text(line.description!, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              line.debit > 0 ? line.debit.toStringAsFixed(2) : '-',
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: line.debit > 0 ? FontWeight.bold : FontWeight.normal,
                                color: line.debit > 0 ? Colors.green[700] : Colors.grey,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              line.credit > 0 ? line.credit.toStringAsFixed(2) : '-',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: line.credit > 0 ? FontWeight.bold : FontWeight.normal,
                                color: line.credit > 0 ? Colors.red[700] : Colors.grey,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // فتح صفحة / حوار ملء شاشة لإضافة قيد يومي يدوي مع التحقق من التوازن
  void _openAddEntryDialog(BuildContext context, ThemeData theme) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AddManualEntryPage(theme: theme),
        );
      },
    );
  }
}

// صفحة/شاشة إدخال القيد اليدوي التفاعلي الجديد
class AddManualEntryPage extends StatefulWidget {
  final ThemeData theme;
  const AddManualEntryPage({Key? key, required this.theme}) : super(key: key);

  @override
  State<AddManualEntryPage> createState() => _AddManualEntryPageState();
}

class _AddManualEntryPageState extends State<AddManualEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _refController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<TempJournalLine> _tempLines = [];

  // للحقل الوسيط الحالي المضاف للجدول
  Account? _selectedAccount;
  final _lineAmountController = TextEditingController();
  final _lineDescController = TextEditingController();
  bool _isDebit = true; // true: مدين، false: دائن

  @override
  void initState() {
    super.initState();
    // إضافة سطرين تمهيديين فارغين لتسهيل وتوجيه المستخدم
    _tempLines = [];
  }

  @override
  void dispose() {
    _descController.dispose();
    _refController.dispose();
    _lineAmountController.dispose();
    _lineDescController.dispose();
    super.dispose();
  }

  // حساب الإجماليات اللحظية
  double get _totalDebits => _tempLines.fold(0.0, (sum, item) => sum + (item.isDebit ? item.amount : 0));
  double get _totalCredits => _tempLines.fold(0.0, (sum, item) => sum + (!item.isDebit ? item.amount : 0));
  double get _difference => (_totalDebits - _totalCredits).abs();
  bool get _isBalanced => _tempLines.isNotEmpty && (_totalDebits - _totalCredits).abs() < 0.001;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JournalEntriesProvider>();
    final accountsList = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل قيد محاسبي يدوي جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: widget.theme.colorScheme.primaryContainer,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // محتوى الحقول الرئيسية
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حقول الترويسة
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDate(context),
                                    icon: const Icon(Icons.calendar_today_rounded),
                                    label: Text(intl.DateFormat('yyyy-MM-dd').format(_selectedDate)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _refController,
                                    decoration: const InputDecoration(
                                      labelText: 'المرجع / السند (اختياري)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descController,
                              validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال شرح أو وصف القيد' : null,
                              decoration: const InputDecoration(
                                labelText: 'بيان وشرح القيد العام',
                                isDense: true,
                                border: OutlineInputBorder(),
                                icon: Icon(Icons.description_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // إشارة التوازن والمؤشرات الحية للأرصدة
                    _buildBalanceIndicatorPanel(),
                    const SizedBox(height: 16),

                    // عنوان قسم الحقول المزدوجة
                    const Text('بنود وقوة السطور (سطرين على الأقل):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),

                    // بنود القيد المضافة حالياً
                    _buildInteractiveLinesList(),
                    const SizedBox(height: 16),

                    // وحدة إدخال سطر جديد يدوي
                    _buildNewLineForm(accountsList),
                  ],
                ),
              ),
            ),

            // شريط الحفظ في الأسفل
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBalanced && _tempLines.length >= 2
                          ? () => _saveJournalEntry(provider)
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      label: const Text('ترحيل وحفظ القيد اليومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء مؤشر توازن القيد اليومي (Live Balanced Validator Badge)
  Widget _buildBalanceIndicatorPanel() {
    final Color color = _isBalanced ? Colors.green : Colors.red;
    final IconData icon = _isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isBalanced 
                        ? 'القيد متوازن وجاهز للترحيل!' 
                        : 'القيد غير متوازن حالياً!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                  ),
                ],
              ),
              if (!_isBalanced && _tempLines.isNotEmpty)
                Text(
                  'الفرق: ${_difference.toStringAsFixed(2)} ر.س',
                  style: TextStyle(fontWeight: FontWeight.extrabold, color: color, fontSize: 12),
                ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleKpiItem('إجمالي المدين (+)', _totalDebits, Colors.green[800]!),
              _buildSimpleKpiItem('إجمالي الدائن (-)', _totalCredits, Colors.red[800]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleKpiItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(2)} ر.س',
          style: TextStyle(fontWeight: FontWeight.extrabold, color: color, fontSize: 13),
        ),
      ],
    );
  }

  // بناء قائمة سطور القيد المضافة تفاعلياً
  Widget _buildInteractiveLinesList() {
    if (_tempLines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: BorderSide(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'لا توجد سطور مضافة بعد للقيد اليدوي.\nاستخدم النموذج أدناه لإضافة طرف مدين وآخر دائن.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tempLines.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final line = _tempLines[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: line.isDebit ? Colors.green[50]?.withOpacity(0.4) : Colors.red[50]?.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            border: BorderSide(
              color: line.isDebit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: line.isDebit ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    line.isDebit ? 'مدين (+)' : 'دائن (-)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: line.isDebit ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${line.account.accountCode}] ${line.account.nameAr}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (line.desc != null && line.desc!.isNotEmpty)
                        Text(
                          line.desc!,
                          style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${line.amount.toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontWeight: FontWeight.extrabold,
                    fontSize: 13,
                    color: line.isDebit ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    setState(() {
                      _tempLines.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // نموذج إضافة سطر جديد من طرف المستخدم
  Widget _buildNewLineForm(List<Account> accounts) {
    return Card(
      color: widget.theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.theme.colorScheme.primary.withOpacity(0.15)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, color: widget.theme.colorScheme.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'إضافة سطر معاملة جديد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // نوع السطر (مدين أو دائن)
            Row(
              children: [
                const Text('طبيعة البند: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('مدين (+)'),
                  selected: _isDebit,
                  selectedColor: Colors.green[100],
                  labelStyle: TextStyle(color: _isDebit ? Colors.green[800] : Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _isDebit = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('دائن (-)'),
                  selected: !_isDebit,
                  selectedColor: Colors.red[100],
                  labelStyle: TextStyle(color: !_isDebit ? Colors.red[800] : Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _isDebit = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // اختيار الحساب المحاسبي من الدليل
            const Text('اختر الحساب المالي المقيد:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Account>(
              value: _selectedAccount,
              isExpanded: true,
              hint: const Text('اختر الحساب المحاسبي...', style: TextStyle(fontSize: 12)),
              style: const TextStyle(fontSize: 12, color: Colors.black),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(),
              ),
              items: accounts.map((acc) {
                return DropdownMenuItem<Account>(
                  value: acc,
                  child: Text('[${acc.accountCode}] ${acc.nameAr}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAccount = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // حقل المبلغ وحقل الشرح البسيط للسطر
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _lineAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'القيمة المالية (ر.س)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _lineDescController,
                    decoration: const InputDecoration(
                      labelText: 'بيان السطر (اختياري)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // زر تأكيد إضافة السطر
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _addNewLineItem,
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('إدراج السطر في الجدول', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // إضافة سطر البند للجدول المؤقت مع التحقق
  void _addNewLineItem() {
    final amount = double.tryParse(_lineAmountController.text) ?? 0.0;
    if (_selectedAccount == null) {
      _showSnackbarError('يرجى اختيار الحساب المحاسبي أولاً!');
      return;
    }
    if (amount <= 0.0) {
      _showSnackbarError('يرجى إدخال مبلغ مالي تزيد قيمته عن صفر!');
      return;
    }

    setState(() {
      _tempLines.add(
        TempJournalLine(
          account: _selectedAccount!,
          amount: amount,
          isDebit: _isDebit,
          desc: _lineDescController.text,
        ),
      );

      // إعادة تصفير مدخلات بنود السطور مع التثبيت البسيط للتوجيه
      _lineAmountController.clear();
      _lineDescController.clear();
      _selectedAccount = null;
    });
  }

  // حفظ في قاعدة البيانات وترحيله
  void _saveJournalEntry(JournalEntriesProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBalanced) {
      _showSnackbarError('لا يمكن ترحيل القيد لأنه غير متوازن!');
      return;
    }
    if (_tempLines.length < 2) {
      _showSnackbarError('القيد المزدوج يجب أن يحتوي على بندين على الأقل لتسجيل حركتي المدين والدائن!');
      return;
    }

    // تجهيز سطور القيود الفعلية
    final List<JournalEntryLine> finalLines = _tempLines.map((temp) {
      return JournalEntryLine(
        accountCode: temp.account.accountCode,
        debit: temp.isDebit ? temp.amount : 0.0,
        credit: !temp.isDebit ? temp.amount : 0.0,
        description: temp.desc,
      );
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.createManualJournalEntry(
      intl.DateFormat('yyyy-MM-dd').format(_selectedDate),
      _descController.text,
      _refController.text,
      finalLines,
    );

    // إغلاق لودر التحميل
    if (mounted) Navigator.of(context).pop();

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ترحيل وحفظ السند والقيد المحاسبي المزدوج بنجاح وتحديث دليل الحسابات!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // إغلاق صفحة الإضافة
      }
    } else {
      _showSnackbarError('حدث خطأ أثناء محاولة ترحيل القيد وحفظ البيانات، يرجى المحاولة لاحقاً.');
    }
  }

  void _showSnackbarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

// نموذج مساعد لتخزين القيم الانتقالية قبل الحفظ الفعلي
class TempJournalLine {
  final Account account;
  final double amount;
  final bool isDebit;
  final String? desc;

  TempJournalLine({
    required this.account,
    required this.amount,
    required this.isDebit,
    this.desc,
  });
}
