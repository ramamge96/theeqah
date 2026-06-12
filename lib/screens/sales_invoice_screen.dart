import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../services/database_service.dart';
import '../models/invoice.dart';
import '../models/contact.dart';
import '../models/inventory_item.dart';
import '../providers/dashboard_provider.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final _dbService = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();

  Contact? _selectedContact;
  List<Contact> _contacts = [];
  List<InventoryItem> _items = [];
  String _paymentType = 'CASH'; // CASH, BANK, CREDITOR
  
  final List<InvoiceLine> _invoiceLines = [];
  double _discountPercent = 0.0;
  bool _isLoading = false;

  // For item addition form
  InventoryItem? _selectedItem;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _dbService.getAllContacts();
      final items = await _dbService.getAllInventoryItems();
      setState(() {
        _contacts = contacts.where((c) => c.type == 'CLIENT').toList();
        _items = items;
      });
    } catch (e) {
      debugPrint("Error loading data in invoice: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _subtotal => _invoiceLines.fold(0.0, (sum, line) => sum + (line.price * line.quantity));
  double get _discountAmount => _subtotal * (_discountPercent / 100);
  double get _taxableAmount => _subtotal - _discountAmount;
  double get _taxAmount => _taxableAmount * 0.15; // 15% VAT
  double get _totalAmount => _taxableAmount + _taxAmount;

  void _addInvoiceLine() {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صنف السلعة أولاً!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final double qty = double.tryParse(_qtyController.text) ?? 1.0;
    final double price = double.tryParse(_priceController.text) ?? _selectedItem!.salePrice;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية يجب أن تكون أكبر من صفر!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (qty > _selectedItem!.quantityInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الكمية المطلوبة ($qty) تفوق المتوفر في المخزن (${_selectedItem!.quantityInStock})!'), backgroundColor: Colors.orange),
      );
    }

    final double lineTax = (price * qty) * 0.15;
    final double lineTotal = (price * qty) + lineTax;

    setState(() {
      _invoiceLines.add(
        InvoiceLine(
          sku: _selectedItem!.sku,
          name: _selectedItem!.name,
          quantity: qty,
          price: price,
          taxAmount: lineTax,
          totalAmount: lineTotal,
        ),
      );

      // Reset item select
      _selectedItem = null;
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  Future<void> _submitInvoice() async {
    if (_invoiceLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حفظ الفاتورة بدون إضافة أصناف أو بنود!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final invoiceNum = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';

      final invoice = Invoice(
        invoiceNumber: invoiceNum,
        contactId: _selectedContact?.id,
        date: intl.DateFormat('yyyy-MM-dd').format(now),
        subtotal: _subtotal,
        discountAmount: _discountAmount,
        taxAmount: _taxAmount,
        totalAmount: _totalAmount,
        paymentType: _paymentType,
        lines: _invoiceLines,
      );

      await _dbService.insertInvoice(invoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ترحيل الفاتورة وتوليد القيد التلقائي بنجاح!'), backgroundColor: Colors.green),
      );

      // Refresh Dashboard Provider to update balances
      if (mounted) {
        context.read<DashboardProvider>().loadDashboardData();
        setState(() {
          _invoiceLines.clear();
          _selectedContact = null;
          _discountPercent = 0.0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حفظ الفاتورة: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _contacts.isEmpty && _items.isEmpty) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء فاتورة مبيعات جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Payment Options
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. تحديد العميل وطريقة السداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Contact>(
                        value: _selectedContact,
                        hint: const Text('عميل نقدي افتراضي'),
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: _contacts.map((c) {
                          return DropdownMenuItem<Contact>(
                            value: c,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedContact = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('طريقة السداد:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'CASH',
                            groupValue: _paymentType,
                            onChanged: (v) => setState(() => _paymentType = v!),
                          ),
                          const Text('الصندوق (نقداً)'),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: 'BANK',
                            groupValue: _paymentType,
                            onChanged: (v) => setState(() => _paymentType = v!),
                          ),
                          const Text('البنك (الشبكة)'),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: 'CREDITOR',
                            groupValue: _paymentType,
                            onChanged: (v) => setState(() => _paymentType = v!),
                          ),
                          const Text('آجل (ذمم مدينة)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Item Select Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. إضافة صنف سلعي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<InventoryItem>(
                        value: _selectedItem,
                        hint: const Text('اختر المنتج...'),
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: _items.map((it) {
                          return DropdownMenuItem<InventoryItem>(
                            value: it,
                            child: Text('${it.name} (المتوفر: ${it.quantityInStock})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedItem = val;
                            if (val != null) {
                              _priceController.text = val.salePrice.toString();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'سعر البيع', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addInvoiceLine,
                        icon: const Icon(Icons.add),
                        label: const Text('إدراج الصنف للفاتورة'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Lines Added Table
              if (_invoiceLines.isNotEmpty) ...[
                const Text('الأصناف المدرجة في الفاتورة الحالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoiceLines.length,
                  itemBuilder: (context, idx) {
                    final line = _invoiceLines[idx];
                    return Card(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        title: Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('الكمية: ${line.quantity} × ${line.price} ر.س | الضريبة (15%)'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${((line.price * line.quantity) + line.taxAmount).toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _invoiceLines.removeAt(idx)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Financial Calculations Card
              Card(
                elevation: 2,
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. ملخص الحسابات الإجمالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Divider(height: 20),
                      _buildSummaryRow('المجموع الجزئي:', '${_subtotal.toStringAsFixed(2)} ر.س'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('خصم تجاري (%):', style: TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: _discountPercent.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                  onChanged: (val) {
                                    setState(() {
                                      _discountPercent = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${_discountAmount.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow('الوعاء المالي الخاضع للضريبة:', '${_taxableAmount.toStringAsFixed(2)} ر.س'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('ضريبة القيمة المضافة (15%):', '${_taxAmount.toStringAsFixed(2)} ر.س'),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الصافي المستحق النهائي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${_totalAmount.toStringAsFixed(2)} ر.س', style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: theme.colorScheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Bar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _invoiceLines.isEmpty ? null : _submitInvoice,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('ترحيل القيد للمخازن والدفاتر وعرض الفاتورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
