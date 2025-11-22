package com.justspent.expense.data.model

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime
import java.util.UUID

/**
 * User entity representing app user preferences and settings
 *
 * @property id Unique identifier for the user
 * @property name User's display name
 * @property email User's email address (optional)
 * @property defaultCurrency ISO 4217 currency code (e.g., "USD", "AED")
 * @property createdAt Timestamp when the user was created
 * @property updatedAt Timestamp when the user was last updated
 */
@Entity(tableName = "users")
data class User(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String = UUID.randomUUID().toString(),

    @ColumnInfo(name = "name")
    val name: String = "User",

    @ColumnInfo(name = "email")
    val email: String? = null,

    @ColumnInfo(name = "default_currency")
    val defaultCurrency: String = "USD",

    @ColumnInfo(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @ColumnInfo(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * Get the currency enum from the stored string
     */
    fun getCurrency(): Currency {
        return Currency.fromCode(defaultCurrency) ?: Currency.USD
    }

    /**
     * Create a copy with updated currency
     */
    fun withCurrency(currency: Currency): User {
        return copy(
            defaultCurrency = currency.code,
            updatedAt = LocalDateTime.now()
        )
    }
}
