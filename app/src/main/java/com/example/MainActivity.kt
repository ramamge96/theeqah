package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.example.data.AppDatabase
import com.example.data.AccountingRepository
import com.example.ui.screens.MainAccountingScreen
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.viewmodel.AccountingViewModel
import com.example.ui.viewmodel.AccountingViewModelFactory

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        // هيئ قاعدة بيانات الحسابات ومستودع تداول القيود والمخزن محلياً
        val database = AppDatabase.getDatabase(applicationContext, lifecycleScope)
        val repository = AccountingRepository(database.accountingDao())
        
        val viewModel: AccountingViewModel by viewModels {
            AccountingViewModelFactory(repository)
        }

        setContent {
            MyApplicationTheme {
                MainAccountingScreen(viewModel = viewModel)
            }
        }
    }
}
