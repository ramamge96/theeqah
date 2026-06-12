@file:OptIn(ExperimentalMaterial3Api::class)
package com.example.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.data.*
import com.example.ui.theme.MoneyGreen
import com.example.ui.theme.ExpenseRed
import com.example.ui.theme.WarningOrange
import com.example.ui.viewmodel.AccountingViewModel
import com.example.ui.viewmodel.LineItemTemp
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun MainAccountingScreen(viewModel: AccountingViewModel) {
    var selectedTab by remember { mutableStateOf(0) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    // استجلاب البيانات من الـ ViewModel
    val accounts by viewModel.accounts.collectAsState()
    val contacts by viewModel.contacts.collectAsState()
    val items by viewModel.items.collectAsState()
    val invoices by viewModel.invoices.collectAsState()
    val journalEntries by viewModel.journalEntries.collectAsState()

    // صناديق الحوار لإضافة الحسابات والعملاء والمنتجات سريعاً لتسهيل التجربة
    var showAddAccountDialog by remember { mutableStateOf(false) }
    var showAddContactDialog by remember { mutableStateOf(false) }
    var showAddItemDialog by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        text = "نظام ثقة المحاسبي المتكامل Enterprise",
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        fontSize = 18.sp
                    )
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                ),
                actions = {
                    IconButton(onClick = {
                        scope.launch {
                            snackbarHostState.showSnackbar("تم تحديث السجلات المالية بنجاح!")
                        }
                    }) {
                        Icon(Icons.Default.Refresh, contentDescription = "تحديث البيانات")
                    }
                }
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                tonalElevation = 8.dp
            ) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.Home, contentDescription = "الرئيسية") },
                    label = { Text("الرئيسية", fontWeight = FontWeight.Bold) }
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(Icons.Default.Create, contentDescription = "إنشاء فاتورة") },
                    label = { Text("إنشاء فاتورة", fontWeight = FontWeight.Bold) }
                )
                NavigationBarItem(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    icon = { Icon(Icons.Default.Menu, contentDescription = "دليل الحسابات") },
                    label = { Text("دليل الحسابات", fontWeight = FontWeight.Bold) }
                )
                NavigationBarItem(
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3 },
                    icon = { Icon(Icons.Default.Settings, contentDescription = "القيود اليومية") },
                    label = { Text("القيود والتقارير", fontWeight = FontWeight.Medium) }
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            when (selectedTab) {
                0 -> DashboardTab(
                    accounts = accounts,
                    invoices = invoices,
                    journalEntries = journalEntries,
                    onNavigateToInvoice = { selectedTab = 1 }
                )
                1 -> InvoiceCreatorTab(
                    viewModel = viewModel,
                    contacts = contacts,
                    items = items,
                    onShowAddContact = { showAddContactDialog = true },
                    onShowAddItem = { showAddItemDialog = true },
                    onSuccess = {
                        scope.launch {
                            snackbarHostState.showSnackbar("تم حفظ الفاتورة وتوليد القيد المحاسبي المزدوج وتحديث المخازن!")
                        }
                        selectedTab = 0 // الانتقال للرئيسية لمراقبة الأرصدة
                    },
                    onError = { err ->
                        scope.launch {
                            snackbarHostState.showSnackbar("فشل: $err")
                        }
                    }
                )
                2 -> ChartOfAccountsTab(
                    accounts = accounts,
                    onAddNewAccount = { showAddAccountDialog = true }
                )
                3 -> JournalEntriesTab(
                    journalEntries = journalEntries,
                    invoices = invoices,
                    accounts = accounts
                )
            }

            // صناديق الحوار المساعدة لوحة التحكم الكبيرة
            if (showAddAccountDialog) {
                AddAccountDialog(
                    onDismiss = { showAddAccountDialog = false },
                    onConfirm = { code, name, type, isDebit ->
                        viewModel.addQuickAccount(code, name, type, isDebit)
                        showAddAccountDialog = false
                        scope.launch { snackbarHostState.showSnackbar("تمت إضافة حساب جديد لدليل الحسابات") }
                    }
                )
            }

            if (showAddContactDialog) {
                AddContactDialog(
                    onDismiss = { showAddContactDialog = false },
                    onConfirm = { name, type, phone ->
                        viewModel.addQuickContact(name, type, phone)
                        showAddContactDialog = false
                        scope.launch { snackbarHostState.showSnackbar("تمت إضافة جهة اتصال جديدة") }
                    }
                )
            }

            if (showAddItemDialog) {
                AddItemDialog(
                    onDismiss = { showAddItemDialog = false },
                    onConfirm = { name, sku, sale, purchase, qty ->
                        viewModel.addQuickItem(name, sku, sale, purchase, qty)
                        showAddItemDialog = false
                        scope.launch { snackbarHostState.showSnackbar("تمت إضافة الصنف المالي وتعريفه بنجاح") }
                    }
                )
            }
        }
    }
}

// ------------------------------------------------------------------------------------
// 1. تبويب الرئيسية (Dashboard)
// ------------------------------------------------------------------------------------
@Composable
fun DashboardTab(
    accounts: List<Account>,
    invoices: List<Invoice>,
    journalEntries: List<JournalEntry>,
    onNavigateToInvoice: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // بطاقات الأرصدة الحية المستمدة من دليل الحسابات
        val cashBalance = accounts.find { it.accountCode == "1101" }?.balance ?: 0.0
        val bankBalance = accounts.find { it.accountCode == "1102" }?.balance ?: 0.0
        val receivablesBalance = accounts.find { it.accountCode == "1103" }?.balance ?: 0.0
        val stockValue = accounts.find { it.accountCode == "1104" }?.balance ?: 0.0
        val totalRevenue = accounts.find { it.accountCode == "4101" }?.balance ?: 0.0
        val totalCOGS = accounts.find { it.accountCode == "5101" }?.balance ?: 0.0

        val totalCapital = accounts.find { it.accountCode == "3101" }?.balance ?: 0.0

        Text(
            text = "مؤشرات الأداء المالي والسيولة الحالية",
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Right
        )

        // الأرصدة النقدية والسيولة
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            DashboardKpiCard(
                title = "رصيد الصندوق الرئيسي",
                value = cashBalance,
                color = MoneyGreen,
                icon = Icons.Default.Home,
                modifier = Modifier.weight(1f)
            )
            DashboardKpiCard(
                title = "بنك الراجحي",
                value = bankBalance,
                color = MaterialTheme.colorScheme.secondary,
                icon = Icons.Default.Home,
                modifier = Modifier.weight(1f)
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            DashboardKpiCard(
                title = "قيمة مخزون المستودع",
                value = stockValue,
                color = WarningOrange,
                icon = Icons.Default.Settings,
                modifier = Modifier.weight(1f)
            )
            DashboardKpiCard(
                title = "مديونية العملاء (الآجل)",
                value = receivablesBalance,
                color = ExpenseRed,
                icon = Icons.Default.Person,
                modifier = Modifier.weight(1f)
            )
        }

        // أداء العمليات (المبيعات، الأرباح، رأس المال)
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "ملخص قائمة الدخل التقديري",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Right
                )
                Spacer(modifier = Modifier.height(12.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = "رقم الحساب", fontWeight = FontWeight.Bold)
                    Text(text = "اسم الحساب المالي", fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f).padding(horizontal = 12.dp), textAlign = TextAlign.Right)
                    Text(text = "الرصيد الحالي", fontWeight = FontWeight.Bold)
                }
                
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                LederRowSimple(code = "4101", name = "إيرادات المبيعات (دائن)", balance = totalRevenue, color = MoneyGreen)
                LederRowSimple(code = "5101", name = "تكلفة البضاعة المباعة (مدين)", balance = totalCOGS, color = ExpenseRed)
                
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

                val grossProfit = totalRevenue - totalCOGS
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "مجمل الربح التقديري",
                        fontWeight = FontWeight.Bold,
                        color = if (grossProfit >= 0) MoneyGreen else ExpenseRed
                    )
                    Text(
                        text = formatCurrency(grossProfit),
                        fontWeight = FontWeight.Bold,
                        color = if (grossProfit >= 0) MoneyGreen else ExpenseRed
                    )
                }
            }
        }

        // إشعار فوري لإنشاء فاتورة جديدة
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Button(
                    onClick = onNavigateToInvoice,
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null)
                        Text("إنشاء فاتورة مبيعات", fontWeight = FontWeight.Bold)
                    }
                }
                Text(
                    text = "هل ترغب بتسجيل مبيعات بضاعة وقيدها تلقائياً؟",
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    textAlign = TextAlign.Right,
                    modifier = Modifier.weight(1f).padding(start = 8.dp)
                )
            }
        }

        // قائمة الفواتير الأخيرة
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "سجل الفواتير الأخيرة في النظام",
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Right,
                modifier = Modifier.fillMaxWidth()
            )

            if (invoices.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "لا توجد فواتير مسجلة حالياً. استخدم تبويب 'إنشاء فاتورة' للبدء.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                        textAlign = TextAlign.Center
                    )
                }
            } else {
                invoices.take(5).forEach { invoice ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = formatCurrency(invoice.totalAmount),
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Column(
                                horizontalAlignment = Alignment.End,
                                modifier = Modifier.weight(1f).padding(end = 12.dp)
                            ) {
                                Text(invoice.contactName, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                Text(
                                    text = "الرقم: ${invoice.invoiceNumber} | الدفع: ${if (invoice.paymentType == "CASH") "نقداً" else if (invoice.paymentType == "BANK") "بنك" else "على الحساب (آجل)"}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(MoneyGreen.copy(alpha = 0.15f))
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = "مبيعات",
                                    color = MoneyGreen,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DashboardKpiCard(
    title: String,
    value: Double,
    color: Color,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.End
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = title,
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                textAlign = TextAlign.Right
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = formatCurrency(value),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = color,
                textAlign = TextAlign.Right
            )
        }
    }
}

@Composable
fun LederRowSimple(code: String, name: String, balance: Double, color: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = code, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
        Text(text = name, fontSize = 13.sp, modifier = Modifier.weight(1f).padding(horizontal = 12.dp), textAlign = TextAlign.Right)
        Text(text = formatCurrency(balance), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = color)
    }
}


// ------------------------------------------------------------------------------------
// 2. شاشة إنشاء الفاتورة وقيد اليومية التلقائي (Invoice Creator)
// ------------------------------------------------------------------------------------
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InvoiceCreatorTab(
    viewModel: AccountingViewModel,
    contacts: List<Contact>,
    items: List<InventoryItem>,
    onShowAddContact: () -> Unit,
    onShowAddItem: () -> Unit,
    onSuccess: () -> Unit,
    onError: (String) -> Unit
) {
    val scope = rememberCoroutineScope()
    
    // قيم الرصد الحالية
    val selectedContactVal by viewModel.selectedContact.collectAsState()
    val paymentTypeVal by viewModel.paymentType.collectAsState()
    val discountPercentVal by viewModel.discountPercent.collectAsState()
    val lineItems by viewModel.invoiceLines.collectAsState()
    val taxRatePercentVal by viewModel.taxRatePercent.collectAsState()

    val subtotalVal by viewModel.subtotal.collectAsState()
    val discountAmountVal by viewModel.discountAmount.collectAsState()
    val taxAmountVal by viewModel.taxAmount.collectAsState()
    val totalAmountVal by viewModel.totalAmount.collectAsState()
    val generatedLinesPreview by viewModel.generatedJournalPreview.collectAsState()

    // لإضافة صنف جديد للفاتورة حالياً
    var selectedItemForAdd by remember { mutableStateOf<InventoryItem?>(null) }
    var itemQtyToAdd by remember { mutableStateOf("1") }
    var itemPriceToAdd by remember { mutableStateOf("") }

    var expandedContactDropdown by remember { mutableStateOf(false) }
    var expandedItemDropdown by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "تسجيل فاتورة مبيعات جديدة وآلية القيد والمخزن",
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = TextAlign.Right
        )

        // 1. اختيار العميل (الآجل أو النقدي)
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onShowAddContact) {
                        Icon(Icons.Default.Add, contentDescription = "عميل جديد سريع")
                    }
                    Text(
                        text = "1. اختيار العميل أو جهة الاتصال",
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }

                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(
                        onClick = { expandedContactDropdown = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = selectedContactVal?.name ?: "اختر العميل (أو اتركه نقدي افتراضي)",
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    DropdownMenu(
                        expanded = expandedContactDropdown,
                        onDismissRequest = { expandedContactDropdown = false },
                        modifier = Modifier.fillMaxWidth(0.9f)
                    ) {
                        DropdownMenuItem(
                            text = { Text("عميل نقدي افتراضي", textAlign = TextAlign.Right, modifier = Modifier.fillMaxWidth()) },
                            onClick = {
                                viewModel.selectedContact.value = null
                                expandedContactDropdown = false
                            }
                        )
                        contacts.filter { it.type == "CLIENT" }.forEach { client ->
                            DropdownMenuItem(
                                text = { Text(client.name, textAlign = TextAlign.Right, modifier = Modifier.fillMaxWidth()) },
                                onClick = {
                                    viewModel.selectedContact.value = client
                                    expandedContactDropdown = false
                                }
                            )
                        }
                    }
                }

                // نوع الدفع
                Text(text = "طريقة الدفع والتأثير على السيولة والعميل:", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // نقدي
                    FilterChip(
                        selected = paymentTypeVal == "CASH",
                        onClick = { viewModel.paymentType.value = "CASH" },
                        label = { Text("نقدي (الصندوق)") },
                        modifier = Modifier.weight(1f)
                    )
                    // بنكي
                    FilterChip(
                        selected = paymentTypeVal == "BANK",
                        onClick = { viewModel.paymentType.value = "BANK" },
                        label = { Text("بنك الراجحي") },
                        modifier = Modifier.weight(1f)
                    )
                    // آجل
                    FilterChip(
                        selected = paymentTypeVal == "CREDITOR",
                        onClick = { viewModel.paymentType.value = "CREDITOR" },
                        label = { Text("آجل (ذمم مبيعات)") },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }

        // 2. إضافة الأصناف إلى الفاتورة
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onShowAddItem) {
                        Icon(Icons.Default.Add, contentDescription = "صنف جديد سريع")
                    }
                    Text("2. إضافة أصناف البضاعة للفاتورة", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                }

                // اختيار الصنف
                Box(modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(
                        onClick = { expandedItemDropdown = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = selectedItemForAdd?.let { "${it.name} - السعر: ${it.salePrice} ر.س" } ?: "اختر صنف السلعة من المخزن...",
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                    DropdownMenu(
                        expanded = expandedItemDropdown,
                        onDismissRequest = { expandedItemDropdown = false },
                        modifier = Modifier.fillMaxWidth(0.9f)
                    ) {
                        items.forEach { stockItem ->
                            val disabled = stockItem.quantityInStock <= 0
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        text = "${stockItem.name} (المتوفر: ${stockItem.quantityInStock} وحدة)",
                                        textAlign = TextAlign.Right,
                                        modifier = Modifier.fillMaxWidth(),
                                        color = if (disabled) Color.Gray else Color.Unspecified
                                    )
                                },
                                onClick = {
                                    selectedItemForAdd = stockItem
                                    itemPriceToAdd = stockItem.salePrice.toString()
                                    expandedItemDropdown = false
                                }
                            )
                        }
                    }
                }

                // حقول إدخال الكمية والسعر التقديري
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedTextField(
                        value = itemQtyToAdd,
                        onValueChange = { itemQtyToAdd = it },
                        label = { Text("الكمية") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = itemPriceToAdd,
                        onValueChange = { itemPriceToAdd = it },
                        label = { Text("سعر البيع الافتراضي") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1.5f),
                        singleLine = true
                    )
                }

                Button(
                    onClick = {
                        val item = selectedItemForAdd
                        if (item == null) {
                            onError("يرجى اختيار صنف السلعة أولاً!")
                            return@Button
                        }
                        val qty = itemQtyToAdd.toIntOrNull() ?: 1
                        if (qty <= 0) {
                            onError("الكمية يجب أن تكون أكبر من صفر!")
                            return@Button
                        }
                        if (qty > item.quantityInStock) {
                            onError("الكمية المطلوبة ($qty) تفوق المتوفر في المخزن الحالي (${item.quantityInStock})!")
                        }
                        val price = itemPriceToAdd.toDoubleOrNull() ?: item.salePrice
                        
                        viewModel.addLineItem(item, qty, price)

                        // إعادة ضبط المدخلات الجزئية
                        selectedItemForAdd = null
                        itemQtyToAdd = "1"
                        itemPriceToAdd = ""
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("أضف السطر إلى الفاتورة", fontWeight = FontWeight.Bold)
                }
            }
        }

        // 3. السطور الحالية المضافة إلى الفاتورة
        if (lineItems.isNotEmpty()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("سطور القيد الحالية المضافة", fontWeight = FontWeight.Bold, fontSize = 13.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                    
                    lineItems.forEach { line ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(onClick = { viewModel.removeLineItem(line.id) }) {
                                Icon(Icons.Default.Delete, contentDescription = "حذف السطر", tint = ExpenseRed)
                            }
                            
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                TextButton(onClick = { viewModel.updateLineItemQuantity(line.id, line.quantity + 1) }) {
                                    Text("+")
                                }
                                Text("${line.quantity} وحدة", fontWeight = FontWeight.Bold)
                                TextButton(onClick = { viewModel.updateLineItemQuantity(line.id, line.quantity - 1) }) {
                                    Text("-")
                                }
                            }

                            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f).padding(horizontal = 8.dp)) {
                                Text(line.item.name, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, textAlign = TextAlign.Right)
                                Text("${formatCurrency(line.customUnitPrice)}/وحدة", fontSize = 11.sp, color = Color.Gray)
                            }
                            
                            Text(formatCurrency(line.total), fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                        }
                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                    }
                }
            }
        }

        // 4. الخصم والضرائب والملخص المالي
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("3. تفاصيل النسب المالية والتخفيضات", fontWeight = FontWeight.Bold, fontSize = 14.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)

                // الخصم بالنسبة المئوية
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Slider(
                        value = discountPercentVal.toFloat(),
                        onValueChange = { viewModel.discountPercent.value = it.toDouble().coerceIn(0.0, 100.0) },
                        valueRange = 0f..50f,
                        steps = 10,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = "خصم: ${discountPercentVal.toInt()}%",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp
                    )
                }

                // ملخص الأرقام المالية النهائية
                HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))
                
                BillingSummaryRow(label = "مجموع الفاتورة قبل الخصم والضريبة", value = subtotalVal)
                BillingSummaryRow(label = "قيمة الخصم التجاري الممنوح", value = discountAmountVal, isNegative = true)
                BillingSummaryRow(label = "الوعاء المالي الخاضع للضريبة", value = subtotalVal - discountAmountVal)
                BillingSummaryRow(label = "ضريبة القيمة المضافة (15% VAT)", value = taxAmountVal)
                
                HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "الصافي المستحق (قوة القيد المالي)",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.secondary
                    )
                    Text(
                        text = formatCurrency(totalAmountVal),
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = MoneyGreen
                    )
                }
            }
        }

        // 5. معاينة القيد اليومي المزدوج المتولد تلقائياً (Live Double-Entry Journal Preview)
        if (generatedLinesPreview.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(MoneyGreen.copy(alpha = 0.15f))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text("متوازن", color = MoneyGreen, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }
                        Text(
                            text = "القيد التجاري المزدوج التلقائي المقترح",
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // ترويسة جدول القيود
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.6f))
                            .padding(6.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(text = "دائن (-)", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(1f), textAlign = TextAlign.Left)
                        Text(text = "مدين (+)", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(1f), textAlign = TextAlign.Left)
                        Text(text = "اسم الحساب المالي المقيد", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(2.5f), textAlign = TextAlign.Right)
                    }

                    generatedLinesPreview.forEach { ledgerLine ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp, horizontal = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            // دائن
                            Text(
                                text = if (ledgerLine.credit > 0.0) formatCurrency(ledgerLine.credit) else "-",
                                fontSize = 12.sp,
                                fontWeight = if (ledgerLine.credit > 0.0) FontWeight.Bold else FontWeight.Normal,
                                color = if (ledgerLine.credit > 0.0) ExpenseRed else Color.Unspecified,
                                modifier = Modifier.weight(1f),
                                textAlign = TextAlign.Left
                            )
                            // مدين
                            Text(
                                text = if (ledgerLine.debit > 0.0) formatCurrency(ledgerLine.debit) else "-",
                                fontSize = 12.sp,
                                fontWeight = if (ledgerLine.debit > 0.0) FontWeight.Bold else FontWeight.Normal,
                                color = if (ledgerLine.debit > 0.0) MoneyGreen else Color.Unspecified,
                                modifier = Modifier.weight(1f),
                                textAlign = TextAlign.Left
                            )
                            // اسم الحساب
                            Text(
                                text = "[${ledgerLine.accountCode}] ${ledgerLine.accountName}",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.weight(2.5f),
                                textAlign = TextAlign.Right
                            )
                        }
                    }

                    val totalCredits = generatedLinesPreview.sumOf { it.credit }
                    val totalDebits = generatedLinesPreview.sumOf { it.debit }
                    
                    HorizontalDivider(modifier = Modifier.padding(vertical = 4.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "إجمالي الدائن: ${formatCurrency(totalCredits)}",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = ExpenseRed,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.Left
                        )
                        Text(
                            text = "إجمالي المدين: ${formatCurrency(totalDebits)}",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = MoneyGreen,
                            modifier = Modifier.weight(1f),
                            textAlign = TextAlign.Left
                        )
                        Text(
                            text = "قيد متوازن ومستودع محدث",
                            fontSize = 11.sp,
                            color = Color.Gray,
                            modifier = Modifier.weight(2.5f),
                            textAlign = TextAlign.Right
                        )
                    }
                }
            }
        }

        // زر الحفظ النهائي والترحيل المباشر
        Button(
            onClick = {
                viewModel.submitInvoice(
                    onSuccess = onSuccess,
                    onError = onError
                )
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Done, contentDescription = null)
                Text("ترحيل القيد ودفتر اليومية وحفظ الفاتورة", fontWeight = FontWeight.Bold, fontSize = 15.sp)
            }
        }
    }
}

@Composable
fun BillingSummaryRow(label: String, value: Double, isNegative: Boolean = false) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
        Text(
            text = (if (isNegative) "-" else "") + formatCurrency(value),
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isNegative) ExpenseRed else Color.Unspecified
        )
    }
}


// ------------------------------------------------------------------------------------
// 3. شجرة الحسابات (Chart of Accounts)
// ------------------------------------------------------------------------------------
@Composable
fun ChartOfAccountsTab(
    accounts: List<Account>,
    onAddNewAccount: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onAddNewAccount) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Text("إضافة حساب مالي")
                }
            }
            Text(
                text = "دليل الحسابات المعتمد (COA)",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
        }

        // عرض قائمة الحسابات مرتبة ومصنفة
        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(accounts) { account ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = formatCurrency(account.balance),
                            fontWeight = FontWeight.Bold,
                            color = if (account.isDebitNormal) MoneyGreen else MaterialTheme.colorScheme.primary
                        )
                        
                        Column(
                            horizontalAlignment = Alignment.End,
                            modifier = Modifier.weight(1f).padding(end = 16.dp)
                        ) {
                            Text(account.nameAr, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                            Text("رقم الحساب: ${account.accountCode}", fontSize = 12.sp, color = Color.Gray)
                        }

                        // شارة نوع الحساب
                        val typeText = when (account.accountType) {
                            "ASSET" -> "أصول"
                            "LIABILITY" -> "خصوم"
                            "EQUITY" -> "حقوق"
                            "REVENUE" -> "إيراد"
                            "EXPENSE" -> "مصروف"
                            else -> account.accountType
                        }
                        val badgeColor = when (account.accountType) {
                            "ASSET" -> MoneyGreen.copy(alpha = 0.15f)
                            "LIABILITY" -> ExpenseRed.copy(alpha = 0.15f)
                            "EQUITY" -> WarningOrange.copy(alpha = 0.15f)
                            else -> MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                        }
                        val badgeTextColor = when (account.accountType) {
                            "ASSET" -> MoneyGreen
                            "LIABILITY" -> ExpenseRed
                            "EQUITY" -> WarningOrange
                            else -> MaterialTheme.colorScheme.primary
                        }

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(6.dp))
                                .background(badgeColor)
                                .padding(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Text(
                                text = typeText,
                                color = badgeTextColor,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}


// ------------------------------------------------------------------------------------
// 4. دفتر قيود اليومية التفصيلي والتقارير (Journal Entries Tab)
// ------------------------------------------------------------------------------------
@Composable
fun JournalEntriesTab(
    journalEntries: List<JournalEntry>,
    invoices: List<Invoice>,
    accounts: List<Account>
) {
    var filterType by remember { mutableStateOf(0) } // 0: الكل، 1: التقارير المالية، 2: تقرير الضريبة المبسط

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "دفتر قيود اليومية والسجلات الضريبية والتقارير",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Right,
                modifier = Modifier.weight(1f)
            )
        }

        // أزرار التصفية
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            FilterChip(
                selected = filterType == 0,
                onClick = { filterType = 0 },
                label = { Text("القيود اليومية", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                modifier = Modifier.weight(1f)
            )
            FilterChip(
                selected = filterType == 1,
                onClick = { filterType = 1 },
                label = { Text("التقارير المالية", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                modifier = Modifier.weight(1.1f)
            )
            FilterChip(
                selected = filterType == 2,
                onClick = { filterType = 2 },
                label = { Text("الإقرار الضريبي (VAT)", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                modifier = Modifier.weight(1.2f)
            )
        }

        if (filterType == 0) {
            if (journalEntries.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("لا توجد قيود محاسبية مسجلة بعد في النظام.", style = MaterialTheme.typography.bodyMedium)
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(journalEntries) { entry ->
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                        ) {
                            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "المستند: ${entry.sourceDocument}",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = formatDate(entry.entryDate),
                                        fontSize = 11.sp,
                                        color = Color.Gray
                                    )
                                }
                                Text(
                                    text = entry.description,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    textAlign = TextAlign.Right,
                                    modifier = Modifier.fillMaxWidth()
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = "القيمة الإجمالية المتوازنة للقيد: ${formatCurrency(entry.totalDebit)}",
                                        fontSize = 12.sp,
                                        color = MoneyGreen,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                        }
                    }
                }
            }
        } else if (filterType == 1) {
            // تفاصيل التقارير المالية الختامية والمرحلية
            var reportSubTab by remember { mutableStateOf(0) } // 0: Trial Balance, 1: Income Stat, 2: Balance Sheet
            
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                TabRow(
                    selectedTabIndex = reportSubTab,
                    containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    contentColor = MaterialTheme.colorScheme.primary
                ) {
                    Tab(selected = reportSubTab == 0, onClick = { reportSubTab = 0 }) {
                        Text("ميزان المراجعة", modifier = Modifier.padding(8.dp), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                    Tab(selected = reportSubTab == 1, onClick = { reportSubTab = 1 }) {
                        Text("قائمة الدخل", modifier = Modifier.padding(8.dp), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                    Tab(selected = reportSubTab == 2, onClick = { reportSubTab = 2 }) {
                        Text("المركز المالي", modifier = Modifier.padding(8.dp), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                }

                when (reportSubTab) {
                    0 -> {
                        // Trial Balance
                        var totalDebits = 0.0
                        var totalCredits = 0.0
                        accounts.forEach { acc ->
                            if (acc.isDebitNormal) {
                                totalDebits += acc.balance
                            } else {
                                totalCredits += acc.balance
                            }
                        }
                        val trialBalanced = Math.abs(totalDebits - totalCredits) < 0.1
                        
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .verticalScroll(rememberScrollState()),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                text = "ميزان المراجعة بالأرصدة المستخرجة من الحسابات",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Right
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(MaterialTheme.colorScheme.surfaceVariant)
                                    .padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text("رصيد دائن (-)", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(1.2f), textAlign = TextAlign.Left)
                                Text("رصيد مدين (+)", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(1.2f), textAlign = TextAlign.Left)
                                Text("اسم الحساب المالي", fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.weight(2.6f), textAlign = TextAlign.Right)
                            }
                            
                            accounts.forEach { acc ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 4.dp, vertical = 6.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(
                                        text = if (!acc.isDebitNormal) formatCurrency(acc.balance) else "-",
                                        fontSize = 11.sp,
                                        modifier = Modifier.weight(1.2f),
                                        textAlign = TextAlign.Left
                                    )
                                    Text(
                                        text = if (acc.isDebitNormal) formatCurrency(acc.balance) else "-",
                                        fontSize = 11.sp,
                                        modifier = Modifier.weight(1.2f),
                                        textAlign = TextAlign.Left
                                    )
                                    Text(
                                        text = "${acc.nameAr} (${acc.accountCode})",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.weight(2.6f),
                                        textAlign = TextAlign.Right
                                    )
                                }
                            }
                            
                            HorizontalDivider()
                            
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f))
                                    .padding(10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = formatCurrency(totalCredits),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = ExpenseRed,
                                    modifier = Modifier.weight(1.2f),
                                    textAlign = TextAlign.Left
                                )
                                Text(
                                    text = formatCurrency(totalDebits),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MoneyGreen,
                                    modifier = Modifier.weight(1.2f),
                                    textAlign = TextAlign.Left
                                )
                                Text(
                                    text = "مجموع ميزان المراجعة",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.weight(2.6f),
                                    textAlign = TextAlign.Right
                                )
                            }
                            
                            Card(
                                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                                colors = CardDefaults.cardColors(containerColor = if (trialBalanced) MoneyGreen.copy(alpha = 0.1f) else ExpenseRed.copy(alpha = 0.1f))
                            ) {
                                Text(
                                    text = if (trialBalanced) "✓ ميزان المراجعة متوازن ومطابق للمعايير المحاسبية المزدوجة." else "⚠ تنبيه: ميزان المراجعة غير متوازن، يرجى مراجعة ترحيلات فواتير اليومية.",
                                    modifier = Modifier.padding(12.dp).fillMaxWidth(),
                                    textAlign = TextAlign.Right,
                                    fontSize = 11.sp,
                                    color = if (trialBalanced) MoneyGreen else ExpenseRed,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                    1 -> {
                        // Income Statement
                        val totalRevenues = accounts.filter { it.accountType == "REVENUE" }.sumOf { it.balance }
                        val totalExpenses = accounts.filter { it.accountType == "EXPENSE" }.sumOf { it.balance }
                        val netProfit = totalRevenues - totalExpenses
                        
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .verticalScroll(rememberScrollState()),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Text(
                                text = "قائمة الدخل - تقرير الأرباح والخسائر التشغيلية",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Right
                            )
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                            ) {
                                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("أولاً: الإيرادات التشغيلية الكلية", fontWeight = FontWeight.Bold, color = MoneyGreen, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                                    val revenueAccounts = accounts.filter { it.accountType == "REVENUE" }
                                    revenueAccounts.forEach { acc ->
                                        BillingSummaryRow(label = acc.nameAr, value = acc.balance)
                                    }
                                    HorizontalDivider()
                                    BillingSummaryRow(label = "إجمالي الإيرادات", value = totalRevenues)
                                }
                            }
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                            ) {
                                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("ثانياً: تكلفة المبيعات والمصاريف العمومية", fontWeight = FontWeight.Bold, color = ExpenseRed, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                                    val expenseAccounts = accounts.filter { it.accountType == "EXPENSE" }
                                    expenseAccounts.forEach { acc ->
                                        BillingSummaryRow(label = acc.nameAr, value = acc.balance, isNegative = true)
                                    }
                                    HorizontalDivider()
                                    BillingSummaryRow(label = "إجمالي التكاليف والمصروفات", value = totalExpenses, isNegative = true)
                                }
                            }
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = formatCurrency(netProfit),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp,
                                        color = if (netProfit >= 0) MoneyGreen else ExpenseRed
                                    )
                                    Text(
                                        text = "صافي ربح الفترة النظيف",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                }
                            }
                        }
                    }
                    2 -> {
                        // Balance Sheet
                        val totalAssets = accounts.filter { it.accountType == "ASSET" }.sumOf { it.balance }
                        val totalLiabilities = accounts.filter { it.accountType == "LIABILITY" }.sumOf { it.balance }
                        val totalEquity = accounts.filter { it.accountType == "EQUITY" }.sumOf { it.balance }
                        val currentProfit = accounts.filter { it.accountType == "REVENUE" }.sumOf { it.balance } - accounts.filter { it.accountType == "EXPENSE" }.sumOf { it.balance }
                        
                        val totalLiabsAndEquity = totalLiabilities + totalEquity + currentProfit
                        
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .verticalScroll(rememberScrollState()),
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Text(
                                text = "المستند الختامي - المركز المالي وميزانية السيولة",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Right
                            )
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                            ) {
                                Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text("الأصول والموجودات (Assets)", fontWeight = FontWeight.Bold, color = MoneyGreen, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                                    accounts.filter { it.accountType == "ASSET" }.forEach { acc ->
                                        BillingSummaryRow(label = "[${acc.accountCode}] ${acc.nameAr}", value = acc.balance)
                                    }
                                    HorizontalDivider()
                                    BillingSummaryRow(label = "إجمالي الأصول", value = totalAssets)
                                }
                            }
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                            ) {
                                Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text("الخصوم والالتزامات المستحقة (Liabilities)", fontWeight = FontWeight.Bold, color = ExpenseRed, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                                    accounts.filter { it.accountType == "LIABILITY" }.forEach { acc ->
                                        BillingSummaryRow(label = "[${acc.accountCode}] ${acc.nameAr}", value = acc.balance)
                                    }
                                    HorizontalDivider()
                                    BillingSummaryRow(label = "إجمالي الخصوم والضرائب المستحقة", value = totalLiabilities)
                                }
                            }
                            
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                            ) {
                                Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Text("حقوق الملكية ورأس المال والأرباح المدورة", fontWeight = FontWeight.Bold, color = WarningOrange, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Right)
                                    accounts.filter { it.accountType == "EQUITY" }.forEach { acc ->
                                        BillingSummaryRow(label = "[${acc.accountCode}] ${acc.nameAr}", value = acc.balance)
                                    }
                                    BillingSummaryRow(label = "أرباح العام الحالية المحققة", value = currentProfit)
                                    HorizontalDivider()
                                    BillingSummaryRow(label = "إجمالي حقوق الملكية والأرباح", value = totalEquity + currentProfit)
                                }
                            }
                            
                            Row(
                                modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.primaryContainer).padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = formatCurrency(totalLiabsAndEquity),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Text(
                                    text = "إجمالي الخصوم وحقوق الملكية:",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                    }
                }
            }
        } else {
            // التقرير الضريبي المبسط
            val totalInvoicesSum = invoices.sumOf { it.totalAmount }
            val vatTaxAmount = invoices.sumOf { it.taxAmount }
            val taxableSales = invoices.sumOf { it.subtotal - it.discountAmount }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(
                            text = "تقرير الإقرار الضريبي المبسط لضريبة القيمة المضافة",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Right
                        )
                        HorizontalDivider()

                        BillingSummaryRow(label = "المبيعات الخاضعة للنسبة القياسية 15%", value = taxableSales)
                        BillingSummaryRow(label = "مجموع ضريبة القيمة المضافة المحصلة (دائن)", value = vatTaxAmount)
                        
                        HorizontalDivider()

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("الصافي المستحق للهيئة الكلي", fontWeight = FontWeight.Bold)
                            Text(formatCurrency(vatTaxAmount), fontWeight = FontWeight.Bold, color = ExpenseRed)
                        }
                    }
                }

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            text = "تنويه واحتراز محاسبي",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            textAlign = TextAlign.Right,
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "يقوم النظام بإعداد القيد المحاسبي التلقائي وترحيل الحسابات المدونة كـ [2101 - ضريبة القيمة المضافة المستحقة] وهو جاهز للمطابقة مع الإقرارات الرسمية للهيئة الزكوية المعتمدة.",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            textAlign = TextAlign.Right,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }
}


// ------------------------------------------------------------------------------------
// 5. حوارات الإدخال السريع (Helper Dialogs)
// ------------------------------------------------------------------------------------
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddAccountDialog(onDismiss: () -> Unit, onConfirm: (String, String, String, Boolean) -> Unit) {
    var code by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf("ASSET") }
    var isDebit by remember { mutableStateOf(true) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "تعريف حساب جديد في الدليل المحاسبي",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Right
                )

                OutlinedTextField(
                    value = code,
                    onValueChange = { code = it },
                    label = { Text("رقم الحساب المالي (مثال: 1105)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("اسم الحساب المالي (مثل: صندوق المعارض)") },
                    modifier = Modifier.fillMaxWidth()
                )

                Text("التصنيف المحاسبي للحساب المالي", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    FilterChip(
                        selected = type == "ASSET",
                        onClick = { type = "ASSET"; isDebit = true },
                        label = { Text("أصول") }
                    )
                    FilterChip(
                        selected = type == "LIABILITY",
                        onClick = { type = "LIABILITY"; isDebit = false },
                        label = { Text("خصوم") }
                    )
                    FilterChip(
                        selected = type == "REVENUE",
                        onClick = { type = "REVENUE"; isDebit = false },
                        label = { Text("إيراد") }
                    )
                    FilterChip(
                        selected = type == "EXPENSE",
                        onClick = { type = "EXPENSE"; isDebit = true },
                        label = { Text("مصروف") }
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(checked = isDebit, onCheckedChange = { isDebit = it })
                    Text("الحساب مدين بطبيعته")
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = {
                            if (code.isNotEmpty() && name.isNotEmpty()) {
                                onConfirm(code, name, type, isDebit)
                            }
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("إضافة")
                    }
                    OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                        Text("إلغاء")
                    }
                }
            }
        }
    }
}

@Composable
fun AddContactDialog(onDismiss: () -> Unit, onConfirm: (String, String, String) -> Unit) {
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var type by remember { mutableStateOf("CLIENT") }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "إضافة جهة اتصال تجارية مالية",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Right
                )

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("اسم العميل أو المورد الكامل") },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = phone,
                    onValueChange = { phone = it },
                    label = { Text("رقم الهاتف") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    FilterChip(
                        selected = type == "CLIENT",
                        onClick = { type = "CLIENT" },
                        label = { Text("عميل للمبيعات") },
                        modifier = Modifier.weight(1f)
                    )
                    FilterChip(
                        selected = type == "SUPPLIER",
                        onClick = { type = "SUPPLIER" },
                        label = { Text("مورد للمشتريات") },
                        modifier = Modifier.weight(1f)
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = {
                            if (name.isNotEmpty()) {
                                onConfirm(name, type, phone)
                            }
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("إضافة")
                    }
                    OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                        Text("إلغاء")
                    }
                }
            }
        }
    }
}

@Composable
fun AddItemDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, String, Double, Double, Int) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var sku by remember { mutableStateOf("") }
    var saleValue by remember { mutableStateOf("") }
    var purchaseValue by remember { mutableStateOf("") }
    var qtyVal by remember { mutableStateOf("10") }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(16.dp)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "تعريف مادة مخزنية وجمركية جديدة",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Right
                )

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("اسم الصنف أو المنتج") },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = sku,
                    onValueChange = { sku = it },
                    label = { Text("رمز الباركود / الحقل الفرعي (SKU)") },
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = saleValue,
                    onValueChange = { saleValue = it },
                    label = { Text("سعر بيع التجزئة (ر.س)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = purchaseValue,
                    onValueChange = { purchaseValue = it },
                    label = { Text("تكلفة الشراء (جملة ر.س)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedTextField(
                    value = qtyVal,
                    onValueChange = { qtyVal = it },
                    label = { Text("الكمية الموفرة الابتدائية في المستودع") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(
                        onClick = {
                            val sale = saleValue.toDoubleOrNull() ?: 0.0
                            val purchase = purchaseValue.toDoubleOrNull() ?: 0.0
                            val qty = qtyVal.toIntOrNull() ?: 0
                            if (name.isNotEmpty()) {
                                onConfirm(name, sku, sale, purchase, qty)
                            }
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("إضافة")
                    }
                    OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                        Text("إلغاء")
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------------
// دوال التنسيق المالي والزمني (Format Helpers)
// ------------------------------------------------------------------------------------
fun formatCurrency(amount: Double): String {
    val format = NumberFormat.getCurrencyInstance(Locale("ar", "SA"))
    return format.format(amount)
}

fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("yyyy/MM/dd HH:mm", Locale("ar", "SA"))
    return sdf.format(Date(timestamp))
}
