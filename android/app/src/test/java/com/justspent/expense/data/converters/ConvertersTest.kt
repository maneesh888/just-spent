package com.justspent.expense.data.converters

import com.google.common.truth.Truth.assertThat
import kotlinx.datetime.LocalDateTime
import org.junit.Test
import java.math.BigDecimal

class ConvertersTest {
    
    @Test
    fun `BigDecimalConverter converts to and from string correctly`() {
        // Given
        val converter = BigDecimalConverter()
        val originalValue = BigDecimal("123.45")
        
        // When
        val stringValue = converter.fromBigDecimal(originalValue)
        val convertedBack = converter.toBigDecimal(stringValue)
        
        // Then
        assertThat(convertedBack).isEqualTo(originalValue)
    }
    
    @Test
    fun `BigDecimalConverter handles null values`() {
        // Given
        val converter = BigDecimalConverter()
        
        // When
        val nullToString = converter.fromBigDecimal(null)
        val nullFromString = converter.toBigDecimal(null)
        
        // Then
        assertThat(nullToString).isNull()
        assertThat(nullFromString).isNull()
    }
    
    @Test
    fun `LocalDateTimeConverter converts to and from string correctly`() {
        // Given
        val converter = LocalDateTimeConverter()
        val originalDateTime = LocalDateTime(2024, 1, 15, 10, 30, 45)
        
        // When
        val stringValue = converter.fromLocalDateTime(originalDateTime)
        val convertedBack = converter.toLocalDateTime(stringValue)
        
        // Then
        assertThat(convertedBack).isEqualTo(originalDateTime)
    }
    
    @Test
    fun `LocalDateTimeConverter handles null values`() {
        // Given
        val converter = LocalDateTimeConverter()
        
        // When
        val nullToString = converter.fromLocalDateTime(null)
        val nullFromString = converter.toLocalDateTime(null)
        
        // Then
        assertThat(nullToString).isNull()
        assertThat(nullFromString).isNull()
    }
    
    @Test
    fun `StringListConverter converts to and from JSON correctly`() {
        // Given
        val converter = StringListConverter()
        val originalList = listOf("item1", "item2", "item3")
        
        // When
        val jsonString = converter.fromStringList(originalList)
        val convertedBack = converter.toStringList(jsonString)
        
        // Then
        assertThat(convertedBack).isEqualTo(originalList)
    }
    
    @Test
    fun `StringListConverter handles empty list`() {
        // Given
        val converter = StringListConverter()
        val emptyList = emptyList<String>()
        
        // When
        val jsonString = converter.fromStringList(emptyList)
        val convertedBack = converter.toStringList(jsonString)
        
        // Then
        assertThat(convertedBack).isEqualTo(emptyList)
    }
    
    @Test
    fun `StringListConverter handles null values`() {
        // Given
        val converter = StringListConverter()
        
        // When
        val nullToString = converter.fromStringList(null)
        val nullFromString = converter.toStringList(null)
        
        // Then
        assertThat(nullToString).isNull()
        assertThat(nullFromString).isNull()
    }
    
    @Test
    fun `BigDecimalConverter preserves precision`() {
        // Given
        val converter = BigDecimalConverter()
        val highPrecisionValue = BigDecimal("123.456789012345")
        
        // When
        val stringValue = converter.fromBigDecimal(highPrecisionValue)
        val convertedBack = converter.toBigDecimal(stringValue)
        
        // Then
        assertThat(convertedBack).isEqualTo(highPrecisionValue)
        assertThat(convertedBack?.scale()).isEqualTo(highPrecisionValue.scale())
    }
    
    @Test
    fun `LocalDateTimeConverter handles different date formats`() {
        // Given
        val converter = LocalDateTimeConverter()
        val dates = listOf(
            LocalDateTime(2024, 1, 1, 0, 0, 0),
            LocalDateTime(2024, 12, 31, 23, 59, 59),
            LocalDateTime(2000, 2, 29, 12, 30, 45) // Leap year
        )
        
        dates.forEach { originalDate ->
            // When
            val stringValue = converter.fromLocalDateTime(originalDate)
            val convertedBack = converter.toLocalDateTime(stringValue)
            
            // Then
            assertThat(convertedBack).isEqualTo(originalDate)
        }
    }
    
    @Test
    fun `StringListConverter handles special characters`() {
        // Given
        val converter = StringListConverter()
        val listWithSpecialChars = listOf(
            "item with spaces",
            "item\"with\"quotes",
            "item,with,commas",
            "item\nwith\nnewlines",
            "item with émojis 🎉"
        )
        
        // When
        val jsonString = converter.fromStringList(listWithSpecialChars)
        val convertedBack = converter.toStringList(jsonString)
        
        // Then
        assertThat(convertedBack).isEqualTo(listWithSpecialChars)
    }
}