package com.example.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.data.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class LineItemTemp(
    val id: String = java.util.UUID.randomUUID().toString(),
    val item: InventoryItem,
    val quantity: Int,
    val customUnitPrice: Double
) {
    val total: Double get() = quantity * customUnitPrice
}

class AccountingViewModel(private val repository: AccountingRepository) : ViewModel() {

    // قوائم البيانات المعروضة في التطبيق
    val accounts: StateFlow<List<Account>> = repository.allAccounts
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val contacts: StateFlow<List<Contact>> = repository.allContacts
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val items: StateFlow<List<InventoryItem>> = repository.allItems
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val invoices: StateFlow<List<Invoice>> = repository.allInvoices
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val journalEntries: StateFlow<List<JournalEntry>> = repository.allJournalEntries
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val journalLines: StateFlow<List<JournalEntryLine>> = repository.allJournalLines
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // --- حالة شاشة إنشاء الفاتورة الجديدة ---
    val selectedContact = MutableStateFlow<Contact?>(null)
    val paymentType = MutableStateFlow("CASH") // CASH, BANK, CREDITOR (آجل)
    val discountPercent = MutableStateFlow(0.0)
    val invoiceLines = MutableStateFlow<List<LineItemTemp>>(emptyList())
    val taxRatePercent = MutableStateFlow(15.0) // الضريبة القياسية في السعودية 15%

    // 1. حساب الإجمالي قبل الخصم (Subtotal)
    val subtotal: StateFlow<Double> = invoiceLines
        .map { list -> list.sumOf { it.total } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // 2. حساب قيمة الخصم (Discount Amount)
    val discountAmount: StateFlow<Double> = combine(subtotal, discountPercent) { subValue, discPercent ->
        subValue * (discPercent / 100.0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // 3. حساب المبلغ الخاضع للضريبة
    val taxableAmount: StateFlow<Double> = combine(subtotal, discountAmount) { subValue, discValue ->
        (subValue - discValue).coerceAtLeast(0.0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // 4. حساب قيمة ضريبة القيمة المضافة (VAT Amount)
    val taxAmount: StateFlow<Double> = combine(taxableAmount, taxRatePercent) { taxValue, tRate ->
        taxValue * (tRate / 100.0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // 5. حساب الصافي النهائي (Grand Total Amount)
    val totalAmount: StateFlow<Double> = combine(taxableAmount, taxAmount) { tAmount, tTax ->
        tAmount + tTax
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // 6. تقدير تكلفة البضاعة المباعة (Estimated Cost of Goods Sold)
    val estimatedCOGS: StateFlow<Double> = invoiceLines
        .map { list -> list.sumOf { it.quantity * it.item.purchasePrice } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0.0)

    // المعاينة الحية للقيود اليومية التلقائية المستنتجة (Live Journal Entry Preview)
    val generatedJournalPreview: StateFlow<List<JournalEntryLine>> = combine(
        paymentType,
        totalAmount,
        taxableAmount,
        taxAmount,
        estimatedCOGS,
        selectedContact
    ) { array ->
        val type = array[0] as String
        val total = array[1] as Double
        val taxable = array[2] as Double
        val taxVal = array[3] as Double
        val cogs = array[4] as Double
        val contact = array[5] as Contact?

        val lines = mutableListOf<JournalEntryLine>()
        if (total <= 0.0) return@combine emptyList()

        // أ) القيد المدين: الصندوق أو البنك أو حساب العملاء
        val debitAccountCode = when (type) {
            "CASH" -> "1101"
            "BANK" -> "1102"
            else -> "1103" // CREDITOR
        }
        val debitAccountName = when (type) {
            "CASH" -> "الصندوق الرئيسي"
            "BANK" -> "بنك الراجحي"
            else -> "حساب العملاء (مدينون): ${contact?.name ?: "عميل آجل"}"
        }
        lines.add(
            JournalEntryLine(
                entryId = 0,
                accountCode = debitAccountCode,
                accountName = debitAccountName,
                debit = total,
                credit = 0.0,
                description = "إثبات مبيعات فاتورة"
            )
        )

        // ب) القيد الدائن الأساسي: إيرادات المبيعات (صافي المبلغ الخاضع للضريبة)
        lines.add(
            JournalEntryLine(
                entryId = 0,
                accountCode = "4101",
                accountName = "إيرادات المبيعات",
                debit = 0.0,
                credit = taxable,
                description = "إيراد المبيعات"
            )
        )

        // ج) القيد الدائن لضريبة القيمة المضافة المستحقة
        if (taxVal > 0.0) {
            lines.add(
                JournalEntryLine(
                    entryId = 0,
                    accountCode = "2101",
                    accountName = "ضريبة القيمة المضافة المستحقة",
                    debit = 0.0,
                    credit = taxVal,
                    description = "ضريبة القيمة المضافة 15%"
                )
            )
        }

        // د) قيود الجرد المستمر (مخزون وتكلفة COGS)
        if (cogs > 0.0) {
            // مدين: تكلفة البضاعة المباعة (مصروف)
            lines.add(
                JournalEntryLine(
                    entryId = 0,
                    accountCode = "5101",
                    accountName = "تكلفة البضاعة المباعة (COGS)",
                    debit = cogs,
                    credit = 0.0,
                    description = "تكلفة البضاعة المباعة لقاء المبيعات"
                )
            )
            // دائن: مخزون المستودع (أصول ينقص)
            lines.add(
                JournalEntryLine(
                    entryId = 0,
                    accountCode = "1104",
                    accountName = "مخزون المستودع الرئيسي",
                    debit = 0.0,
                    credit = cogs,
                    description = "صرف بضاعة مباعة من المخزن"
                )
            )
        }

        lines
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // --- العمليات على قائمة سطور الفاتورة ---
    fun addLineItem(item: InventoryItem, qty: Int, price: Double) {
        val currentList = invoiceLines.value
        val existing = currentList.find { it.item.id == item.id }
        if (existing != null) {
            invoiceLines.value = currentList.map {
                if (it.item.id == item.id) {
                    it.copy(quantity = it.quantity + qty, customUnitPrice = price)
                } else it
            }
        } else {
            invoiceLines.value = currentList + LineItemTemp(item = item, quantity = qty, customUnitPrice = price)
        }
    }

    fun removeLineItem(lineId: String) {
        invoiceLines.value = invoiceLines.value.filter { it.id != lineId }
    }

    fun updateLineItemQuantity(lineId: String, newQty: Int) {
        if (newQty <= 0) {
            removeLineItem(lineId)
            return
        }
        invoiceLines.value = invoiceLines.value.map {
            if (it.id == lineId) it.copy(quantity = newQty) else it
        }
    }

    // --- تقديم وحفظ الفاتورة النهائية ---
    fun submitInvoice(onSuccess: () -> Unit, onError: (String) -> Unit) {
        val currentLines = invoiceLines.value
        if (currentLines.isEmpty()) {
            onError("لا يمكن حفظ فاتورة فارغة. يرجى إضافة صنف واحد على الأقل!")
            return
        }

        val contactVal = selectedContact.value
        if (paymentType.value == "CREDITOR" && contactVal == null) {
            onError("للبيع الآجل، يرجى اختيار العميل أولاً!")
            return
        }

        // إسناد جهة اتصال افتراضية للمبيعات النقدية إذا لم يتم اختيار عميل محدد
        val contactId = contactVal?.id ?: 1L // أول عميل عموماً
        val contactName = contactVal?.name ?: "عميل نقدي"

        viewModelScope.launch {
            try {
                val invoiceNum = "INV-${System.currentTimeMillis() / 1000}"
                
                val invoice = Invoice(
                    invoiceNumber = invoiceNum,
                    invoiceType = "SALES",
                    contactId = contactId,
                    contactName = contactName,
                    subtotal = subtotal.value,
                    discountPercent = discountPercent.value,
                    discountAmount = discountAmount.value,
                    taxRate = taxRatePercent.value,
                    taxAmount = taxAmount.value,
                    totalAmount = totalAmount.value,
                    paymentType = paymentType.value
                )

                // تحويل لسطور الكيان الخاصة بقاعدة البيانات
                val linesToSave = currentLines.map { temp ->
                    InvoiceLine(
                        invoiceId = 0, // تحدد في DAO تلقائياً
                        itemId = temp.item.id,
                        itemName = temp.item.name,
                        quantity = temp.quantity,
                        unitPrice = temp.customUnitPrice,
                        lineTotal = temp.total
                    )
                }

                // إنشاء قيد رأس القيد
                val journalEntry = JournalEntry(
                    description = "قيد توليد تلقائي لفاتورة مبيعات رقم $invoiceNum",
                    totalDebit = totalAmount.value + estimatedCOGS.value,
                    totalCredit = totalAmount.value + estimatedCOGS.value
                )

                // توليد السطور وتحديث الأرقام
                val journalLinesToSave = generatedJournalPreview.value

                // الحفظ الذري
                repository.saveInvoiceWithJournalEntries(
                    invoice,
                    linesToSave,
                    journalEntry,
                    journalLinesToSave
                )

                // تهيئة الحقول للشاشة تمهيداً لعملية جديدة
                clearInvoiceForm()
                onSuccess()
            } catch (e: Exception) {
                onError("أخطأ حفظ البيانات: ${e.localizedMessage}")
            }
        }
    }

    private fun clearInvoiceForm() {
        selectedContact.value = null
        paymentType.value = "CASH"
        discountPercent.value = 0.0
        invoiceLines.value = emptyList()
    }

    // --- العمليات على دليل الحسابات وجهات الاتصال مباشرة ---
    fun addQuickAccount(code: String, name: String, type: String, isDebit: Boolean) {
        viewModelScope.launch {
            repository.insertAccount(
                Account(
                    accountCode = code,
                    nameAr = name,
                    nameEn = name,
                    accountType = type,
                    isDebitNormal = isDebit,
                    isActive = true
                )
            )
        }
    }

    fun addQuickContact(name: String, type: String, phone: String) {
        viewModelScope.launch {
            repository.insertContact(
                Contact(
                    name = name,
                    type = type,
                    phone = phone,
                    openingBalance = 0.0,
                    currentBalance = 0.0
                )
            )
        }
    }

    fun addQuickItem(name: String, sku: String, salePrice: Double, purchasePrice: Double, quantity: Int) {
        viewModelScope.launch {
            repository.insertItem(
                InventoryItem(
                    name = name,
                    sku = sku,
                    salePrice = salePrice,
                    purchasePrice = purchasePrice,
                    quantityInStock = quantity
                )
            )
        }
    }
}

class AccountingViewModelFactory(private val repository: AccountingRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(AccountingViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return AccountingViewModel(repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
