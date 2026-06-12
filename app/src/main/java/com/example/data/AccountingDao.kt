package com.example.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface AccountingDao {
    // Accounts
    @Query("SELECT * FROM accounts ORDER BY accountCode ASC")
    fun getAllAccounts(): Flow<List<Account>>

    @Query("SELECT * FROM accounts WHERE accountCode = :code LIMIT 1")
    suspend fun getAccountByCode(code: String): Account?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAccount(account: Account)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAccounts(accounts: List<Account>)

    @Query("UPDATE accounts SET balance = balance + :amount WHERE accountCode = :code")
    suspend fun updateAccountBalance(code: String, amount: Double)

    // Contacts
    @Query("SELECT * FROM contacts ORDER BY name ASC")
    fun getAllContacts(): Flow<List<Contact>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContact(contact: Contact)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContacts(contacts: List<Contact>)

    @Query("UPDATE contacts SET currentBalance = currentBalance + :amount WHERE id = :id")
    suspend fun updateContactBalance(id: Long, amount: Double)

    // Items
    @Query("SELECT * FROM inventory_items ORDER BY name ASC")
    fun getAllItems(): Flow<List<InventoryItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItem(item: InventoryItem)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertItems(items: List<InventoryItem>)

    @Query("UPDATE inventory_items SET quantityInStock = quantityInStock - :qty WHERE id = :id")
    suspend fun deductInventory(id: Long, qty: Int)

    // Invoices & Lines
    @Query("SELECT * FROM invoices ORDER BY id DESC")
    fun getAllInvoices(): Flow<List<Invoice>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertInvoice(invoice: Invoice): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertInvoiceLines(lines: List<InvoiceLine>)

    @Query("SELECT * FROM invoice_lines WHERE invoiceId = :invoiceId")
    fun getLinesForInvoice(invoiceId: Long): Flow<List<InvoiceLine>>

    // Journal Entries & Lines
    @Query("SELECT * FROM journal_entries ORDER BY id DESC")
    fun getAllJournalEntries(): Flow<List<JournalEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertJournalEntry(entry: JournalEntry): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertJournalLines(lines: List<JournalEntryLine>)

    @Query("SELECT * FROM journal_entry_lines ORDER BY id ASC")
    fun getAllJournalLines(): Flow<List<JournalEntryLine>>

    @Query("SELECT * FROM journal_entry_lines WHERE entryId = :entryId")
    fun getLinesForJournalEntry(entryId: Long): Flow<List<JournalEntryLine>>

    // حفظ الفاتورة وإنشاء القيود المحاسبية وتعديل المخزون وأرصدة العملاء دفعة واحدة بشكل ذري
    @Transaction
    suspend fun saveInvoiceWithJournalEntries(
        invoice: Invoice,
        lines: List<InvoiceLine>,
        journalEntry: JournalEntry,
        journalLines: List<JournalEntryLine>
    ) {
        // 1. حفظ الفاتورة الأساسية
        val invoiceId = insertInvoice(invoice)
        
        // 2. ربط سطور الفاتورة بالمعرف الأساسي وحفظها
        val finalizedLines = lines.map { it.copy(invoiceId = invoiceId) }
        insertInvoiceLines(finalizedLines)

        // 3. حفظ قيد اليومية التلقائي
        val entryId = insertJournalEntry(journalEntry.copy(sourceDocument = "فاتورة #$invoiceId"))
        
        // 4. ربط السطور ومعرف القيد اليومي وحفظها
        val finalizedJournalLines = journalLines.map { it.copy(entryId = entryId) }
        insertJournalLines(finalizedJournalLines)

        // 5. خصم الكميات من المخزون وتحديث أرصدة حسابات الأصول والمبيعات
        for (line in finalizedLines) {
            deductInventory(line.itemId, line.quantity)
        }

        // 6. تحديث الأرصدة في دليل الحسابات
        for (jLine in finalizedJournalLines) {
            val isDebit = jLine.debit > 0
            val signedAmount = if (isDebit) jLine.debit else jLine.credit
            
            val acc = getAccountByCode(jLine.accountCode)
            if (acc != null) {
                // إذا كان الحساب مدين بطبيعته (كالنقدية والأصول والمصروفات)
                // فإن القيد المدين يزيده والدائن يقلله
                val change = if (acc.isDebitNormal) {
                    if (isDebit) signedAmount else -signedAmount
                } else {
                    // إذا كان الحساب دائن بطبيعته (كالخصوم وحقوق الملكية والمبيعات)
                    // فإن القيد الدائن يزيده والمدين يقلله
                    if (isDebit) -signedAmount else signedAmount
                }
                updateAccountBalance(jLine.accountCode, change)
            }
        }

        // 7. تحديث رصيد العميل أو المورد الخاص بجهة الاتصال
        if (invoice.paymentType == "CREDITOR") {
            // البيع الآجل يزيد رصيد مديونية العميل (الأصول)، والشراء الآجل يزيد رصيد المورد (الخصوم)
            val balanceChange = if (invoice.invoiceType == "SALES") invoice.totalAmount else -invoice.totalAmount
            updateContactBalance(invoice.contactId, balanceChange)
        }
    }
}
