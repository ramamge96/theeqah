package com.example.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(
    entities = [
        Account::class,
        Contact::class,
        InventoryItem::class,
        Invoice::class,
        InvoiceLine::class,
        JournalEntry::class,
        JournalEntryLine::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun accountingDao(): AccountingDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context, scope: CoroutineScope): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "accounting_database"
                )
                .addCallback(AccountingDatabaseCallback(scope))
                .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class AccountingDatabaseCallback(
        private val scope: CoroutineScope
    ) : RoomDatabase.Callback() {

        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            INSTANCE?.let { database ->
                scope.launch(Dispatchers.IO) {
                    populateDatabase(database.accountingDao())
                }
            }
        }

        suspend fun populateDatabase(dao: AccountingDao) {
            // 1. تهيئة دليل الحسابات الافتراضي (Chart of Accounts)
            val initialAccounts = listOf(
                Account("1101", "الصندوق الرئيسي", "Main Cash Safe", "ASSET", isDebitNormal = true, balance = 50000.0),
                Account("1102", "بنك الراجحي", "Al Rajhi Bank", "ASSET", isDebitNormal = true, balance = 120000.0),
                Account("1103", "حساب العملاء (مدينون)", "Accounts Receivable", "ASSET", isDebitNormal = true, balance = 0.0),
                Account("1104", "مخزون المستودع الرئيسي", "Main Warehousing Stock", "ASSET", isDebitNormal = true, balance = 25000.0),
                Account("2101", "ضريبة القيمة المضافة المستحقة", "VAT Payable", "LIABILITY", isDebitNormal = false, balance = 0.0),
                Account("2102", "حساب الموردين (دائنون)", "Accounts Payable", "LIABILITY", isDebitNormal = false, balance = 0.0),
                Account("3101", "رأس المال", "Capital Corporate", "EQUITY", isDebitNormal = false, balance = 195000.0),
                Account("4101", "إيرادات المبيعات", "Sales Revenues", "REVENUE", isDebitNormal = false, balance = 0.0),
                Account("5101", "تكلفة البضاعة المباعة (COGS)", "Cost of Goods Sold", "EXPENSE", isDebitNormal = true, balance = 0.0),
                Account("5102", "مصروف الإيجار", "Rent Expense", "EXPENSE", isDebitNormal = true, balance = 0.0),
                Account("5103", "مصروف الرواتب", "Salaries Expense", "EXPENSE", isDebitNormal = true, balance = 0.0)
            )
            dao.insertAccounts(initialAccounts)

            // 2. تهيئة جهات الاتصال الافتراضية (Contacts)
            val initialContacts = listOf(
                Contact(name = "مؤسسة الأمل التجارية (عميل)", type = "CLIENT", phone = "0501234567", openingBalance = 0.0, currentBalance = 0.0),
                Contact(name = "شركة بن لادن للمقاولات (عميل آجل)", type = "CLIENT", phone = "0543210987", openingBalance = 0.0, currentBalance = 0.0),
                Contact(name = "الشركة العربية للتوريدات (مورد)", type = "SUPPLIER", phone = "0569876543", openingBalance = 0.0, currentBalance = 0.0)
            )
            dao.insertContacts(initialContacts)

            // 3. تهيئة المنتجات أو البضائع الافتراضية
            val initialItems = listOf(
                InventoryItem(name = "جهاز كمبيوتر محمول Intel i7", sku = "SKU-LAP-I7", salePrice = 3500.0, purchasePrice = 2700.0, quantityInStock = 45),
                InventoryItem(name = "شاشة ذكية 55 بوصة OLED", sku = "SKU-SMR-TV55", salePrice = 2400.0, purchasePrice = 1800.0, quantityInStock = 20),
                InventoryItem(name = "طابعة ليزرية للمكاتب", sku = "SKU-PRN-LSR", salePrice = 850.0, purchasePrice = 600.0, quantityInStock = 12)
            )
            dao.insertItems(initialItems)
        }
    }
}
