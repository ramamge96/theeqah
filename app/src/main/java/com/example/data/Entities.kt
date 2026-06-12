package com.example.data

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class AccountType(val displayNameAr: String) {
    ASSET("أصول"),
    LIABILITY("خصوم"),
    EQUITY("حقوق ملكية"),
    REVENUE("إيرادات"),
    EXPENSE("مصروفات")
}

@Entity(tableName = "accounts")
data class Account(
    @PrimaryKey
    val accountCode: String, // مثلاً "1101", "2103"
    val nameAr: String,
    val nameEn: String,
    val accountType: String, // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    val parentCode: String? = null,
    val level: Int = 1,
    val isDebitNormal: Boolean = true,
    val isActive: Boolean = true,
    val balance: Double = 0.0
)

@Entity(tableName = "contacts")
data class Contact(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val type: String, // CLIENT (عميل), SUPPLIER (مورد)
    val phone: String = "",
    val openingBalance: Double = 0.0,
    val currentBalance: Double = 0.0
)

@Entity(tableName = "inventory_items")
data class InventoryItem(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val sku: String = "",
    val salePrice: Double = 0.0,
    val purchasePrice: Double = 0.0,
    val quantityInStock: Int = 100, // مخزون ابتدائي افتراضي للتجربة
    val minThreshold: Int = 5
)

@Entity(tableName = "invoices")
data class Invoice(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val invoiceNumber: String,
    val invoiceType: String, // SALES, PURCHASE
    val contactId: Long,
    val contactName: String,
    val date: Long = System.currentTimeMillis(),
    val subtotal: Double = 0.0,
    val discountPercent: Double = 0.0,
    val discountAmount: Double = 0.0,
    val taxRate: Double = 15.0, // نسبة الضريبة مثلاً 15%
    val taxAmount: Double = 0.0,
    val totalAmount: Double = 0.0,
    val paymentType: String = "CASH" // CASH, CREDITOR, BANK
)

@Entity(tableName = "invoice_lines")
data class InvoiceLine(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val invoiceId: Long,
    val itemId: Long,
    val itemName: String,
    val quantity: Int,
    val unitPrice: Double,
    val lineTotal: Double
)

@Entity(tableName = "journal_entries")
data class JournalEntry(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val entryDate: Long = System.currentTimeMillis(),
    val description: String,
    val sourceDocument: String = "", // رقم الفاتورة أو المستند المصدر
    val totalDebit: Double = 0.0,
    val totalCredit: Double = 0.0
)

@Entity(tableName = "journal_entry_lines")
data class JournalEntryLine(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val entryId: Long,
    val accountCode: String,
    val accountName: String,
    val debit: Double = 0.0,
    val credit: Double = 0.0,
    val description: String = ""
)
