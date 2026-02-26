package com.justspent.expense.data.model

import kotlinx.datetime.LocalDateTime
import java.math.BigDecimal

data class ExpenseData(
    val amount: BigDecimal,
    val currency: String,
    val category: String,
    val merchant: String? = null,
    val notes: String? = null,
    val transactionDate: LocalDateTime,
    val source: String,
    val voiceTranscript: String? = null
)