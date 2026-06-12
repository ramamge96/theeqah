package com.example.data

import kotlinx.coroutines.flow.Flow

class AccountingRepository(private val dao: AccountingDao) {
    val allAccounts: Flow<List<Account>> = dao.getAllAccounts()
    val allContacts: Flow<List<Contact>> = dao.getAllContacts()
    val allItems: Flow<List<InventoryItem>> = dao.getAllItems()
    val allInvoices: Flow<List<Invoice>> = dao.getAllInvoices()
    val allJournalEntries: Flow<List<JournalEntry>> = dao.getAllJournalEntries()
    val allJournalLines: Flow<List<JournalEntryLine>> = dao.getAllJournalLines()

    suspend fun insertAccount(account: Account) {
        dao.insertAccount(account)
    }

    suspend fun insertContact(contact: Contact) {
        dao.insertContact(contact)
    }

    suspend fun insertItem(item: InventoryItem) {
        dao.insertItem(item)
    }

    suspend fun saveInvoiceWithJournalEntries(
        invoice: Invoice,
        lines: List<InvoiceLine>,
        journalEntry: JournalEntry,
        journalLines: List<JournalEntryLine>
    ) {
        dao.saveInvoiceWithJournalEntries(invoice, lines, journalEntry, journalLines)
    }
}
