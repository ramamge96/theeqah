import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/invoice.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Directionality(
      textDirection: TextDirection.rtl, // دعم الواجهة العربية بالكامل لليمين واليسار
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة التحكم المالية والتحليلات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<DashboardProvider>().loadDashboardData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث البيانات المالية الحية')),
                );
              },
            ),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. الترويسة الترحيبية
                    _buildWelcomeHeader(theme),
                    const SizedBox(height: 16),

                    // 2. بطاقات الأداء المالي الرئيسي (KPI Grid)
                    _buildKPIsGrid(provider, theme),
                    const SizedBox(height: 24),

                    // 3. الرسم البياني للمبيعات والإيرادات الشهرية
                    _buildRevenueBarChart(provider, theme),
                    const SizedBox(height: 24),

                    // 4. جدول/قائمة آخر 5 فواتير مبيعات
                    _buildRecentInvoicesList(provider, theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // الترويسة الترحيبية مع التاريخ واليوم المالي
  Widget _buildWelcomeHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_rounded, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'التقرير المالي اللحظي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.extrabold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'متابعة شاملة للميزانية العمومية، التدفقات النقدية، والأرباح التشغيلية.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // شبكة بطاقات الأداء المالي الملونة
  Widget _buildKPIsGrid(DashboardProvider provider, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildKPICard(
          title: 'إجمالي الأصول',
          value: provider.totalAssets,
          icon: Icons.account_balance_wallet_rounded,
          accentColor: Colors.green[700]!,
          description: 'نقدية، عملاء، مخزون وممتلكات',
          theme: theme,
        ),
        _buildKPICard(
          title: 'الخصوم / المطلوبات',
          value: provider.totalLiabilities,
          icon: Icons.payment_rounded,
          accentColor: Colors.red[700]!,
          description: 'مستحقات موردين وقروض وضرائب',
          theme: theme,
        ),
        _buildKPICard(
          title: 'حقوق الملكية',
          value: provider.totalEquity,
          icon: Icons.pie_chart_rounded,
          accentColor: Colors.blueGrey[700]!,
          description: 'رأس المال المدفوع والاحتياطيات',
          theme: theme,
        ),
        _buildKPICard(
          title: 'صافي الأرباح/الخسائر',
          value: provider.netProfitOrLoss,
          icon: provider.netProfitOrLoss >= 0 
              ? Icons.trending_up_rounded 
              : Icons.trending_down_rounded,
          accentColor: provider.netProfitOrLoss >= 0 ? Colors.teal[700]! : Colors.deepOrange[700]!,
          description: 'الإيرادات التشغيلية - المصاريف',
          theme: theme,
        ),
      ],
    );
  }

  // بطاقة ذكية منفردة للارقام القياسية مع تأثيرات بصرية
  Widget _buildKPICard({
    required String title,
    required double value,
    required IconData icon,
    required Color accentColor,
    required String description,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withOpacity(0.15), width: 1.5),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.extrabold,
                color: accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              description,
              maxLines: 1,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // رسم بياني مبتكر وتفاعلي للأرباح والإيرادات الشهرية باستخدام الحاويات
  Widget _buildRevenueBarChart(DashboardProvider provider, ThemeData theme) {
    // بيانات افتراضية تمثيلية لإظهار نشاط الشركة بصورة متميزة
    final List<Map<String, dynamic>> monthlyData = [
      {'month': 'يناير', 'revenue': 12000.0, 'expense': 9000.0},
      {'month': 'فبراير', 'revenue': 18500.0, 'expense': 11000.0},
      {'month': 'مارس', 'revenue': 15000.0, 'expense': 10500.0},
      {'month': 'أبريل', 'revenue': 22000.0, 'expense': 14000.0},
      {'month': 'مايو', 'revenue': 28000.0, 'expense': 16500.0},
      {'month': 'يونيو', 'revenue': 34500.0, 'expense': 19000.0},
    ];

    // تحديد الحد الأقصى للمبيعات لضبط مقياس الارتفاع
    double maxRevenue = 0.0;
    for (var data in monthlyData) {
      if (data['revenue'] > maxRevenue) maxRevenue = data['revenue'];
    }
    if (maxRevenue == 0) maxRevenue = 1.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليلات الإيرادات مقابل المصروفات',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'مخطط مقارنة التدفقات النقدية والتشغيلية',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                // مؤشرات التلوين للتوضيح البصري
                Row(
                  children: [
                    _buildLegendItem(label: 'إيراد', color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    _buildLegendItem(label: 'مصروف', color: Colors.deepOrangeAccent),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // مخطط الأعمدة الشجرية
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.map((data) {
                  final double revHeightFactor = data['revenue'] / maxRevenue;
                  final double expHeightFactor = data['expense'] / maxRevenue;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // عمود الإيرادات
                            Container(
                              width: 12,
                              height: (revHeightFactor * 130).clamp(10.0, 130.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primaryContainer,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // عمود المصروفات
                            Container(
                              width: 12,
                              height: (expHeightFactor * 130).clamp(10.0, 130.0),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepOrangeAccent,
                                    Colors.orangeAccent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['month'] as String,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // قائمة آخر 5 فواتير مبيعات
  Widget _buildRecentInvoicesList(DashboardProvider provider, ThemeData theme) {
    final list = provider.lastInvoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'آخر فواتير المبيعات الصادرة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text(
              'الإجمالي: ${list.length} فواتير',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        list.isEmpty
            ? _buildNoTransactionsCard(theme)
            : ListView.builder(
                itemCount: list.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final invoice = list[index];
                  // البحث عن اسم جهة الاتصال
                  final contactName = provider.contactNames[invoice.contactId] ?? 'عميل مجهول';

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Row(
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 13.5),
                          ),
                          const Spacer(),
                          Text(
                            '${invoice.totalAmount.toStringAsFixed(2)} ر.س',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'العميل: $contactName | التاريخ: ${invoice.date}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          _buildPaymentBadge(invoice.paymentType, theme),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // شارة تلوين حالة السداد
  Widget _buildPaymentBadge(String type, ThemeData theme) {
    Color bg;
    Color fg;
    String text;

    switch (type) {
      case 'CASH':
        bg = Colors.green[50]!;
        fg = Colors.green[800]!;
        text = 'نقدي';
        break;
      case 'BANK':
        bg = Colors.blue[50]!;
        fg = Colors.blue[800]!;
        text = 'شبكة / بنك';
        break;
      case 'CREDITOR':
        bg = Colors.orange[50]!;
        fg = Colors.orange[800]!;
        text = 'آجل (ذمم)';
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[700]!;
        text = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // حالة فارغة للفواتير
  Widget _buildNoTransactionsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.feed_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text(
                'لا توجد فواتير مبيعات مسجلة حالياً',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
