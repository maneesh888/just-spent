package com.justspent.expense.data.model

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.justspent.expense.data.converters.BigDecimalConverter
import com.justspent.expense.data.converters.LocalDateTimeConverter
import com.justspent.expense.data.converters.StringListConverter
import kotlinx.datetime.LocalDateTime
import java.math.BigDecimal
import java.util.UUID

@Entity(tableName = "expenses")
@TypeConverters(
    BigDecimalConverter::class,
    LocalDateTimeConverter::class,
    StringListConverter::class
)
data class Expense(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    
    @ColumnInfo(name = "user_id")
    val userId: String = "default_user", // For future multi-user support
    
    @ColumnInfo(name = "amount")
    val amount: BigDecimal,
    
    @ColumnInfo(name = "currency")
    val currency: String,
    
    @ColumnInfo(name = "category")
    val category: String,
    
    @ColumnInfo(name = "merchant")
    val merchant: String? = null,
    
    @ColumnInfo(name = "notes")
    val notes: String? = null,
    
    @ColumnInfo(name = "transaction_date")
    val transactionDate: LocalDateTime,
    
    @ColumnInfo(name = "created_at")
    val createdAt: LocalDateTime,
    
    @ColumnInfo(name = "updated_at")
    val updatedAt: LocalDateTime,
    
    @ColumnInfo(name = "source")
    val source: String,
    
    @ColumnInfo(name = "voice_transcript")
    val voiceTranscript: String? = null,
    
    @ColumnInfo(name = "status")
    val status: String = "active",
    
    @ColumnInfo(name = "is_recurring")
    val isRecurring: Boolean = false,
    
    @ColumnInfo(name = "recurring_id")
    val recurringId: String? = null
)