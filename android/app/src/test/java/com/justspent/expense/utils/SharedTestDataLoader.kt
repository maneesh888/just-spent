package com.justspent.expense.utils

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString
import java.io.File

/**
 * Loader for shared test data from JSON files
 * Loads test data from shared/test-data/ directory
 */
object SharedTestDataLoader {

    private val json = Json { ignoreUnknownKeys = true }

    /**
     * Voice test data structure
     */
    @Serializable
    data class VoiceTestData(
        val version: String,
        val description: String,
        val test_suites: TestSuites
    )

    @Serializable
    data class TestSuites(
        val currency_detection: TestSuite,
        val amount_extraction: TestSuite,
        val written_numbers: TestSuite,
        val real_world_scenarios: TestSuite,
        val edge_cases: TestSuite,
        val symbol_normalization: TestSuite,
        val disambiguation: TestSuite
    )

    @Serializable
    data class TestSuite(
        val description: String,
        val tests: List<VoiceTestCase>
    )

    @Serializable
    data class VoiceTestCase(
        val id: String,
        val input: String,
        val expected_currency: String? = null,
        val expected_amount: Double? = null,
        val expected_category: String? = null,
        val expected_merchant: String? = null,
        val description: String,
        val default_currency: String? = null,
        val normalized_output: String? = null,
        val expected_behavior: String? = null,
        val note: String? = null
    )

    /**
     * Load voice test data
     */
    fun loadVoiceTestData(): VoiceTestData {
        val jsonFile = File("../../shared/test-data/voice-test-data.json")
        require(jsonFile.exists()) { "Voice test data file not found: ${jsonFile.absolutePath}" }

        val jsonContent = jsonFile.readText()
        return json.decodeFromString<VoiceTestData>(jsonContent)
    }

    /**
     * Get specific test suite
     */
    fun getCurrencyDetectionTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.currency_detection.tests
    }

    fun getAmountExtractionTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.amount_extraction.tests
    }

    fun getWrittenNumberTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.written_numbers.tests
    }

    fun getEdgeCaseTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.edge_cases.tests
    }

    fun getRealWorldTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.real_world_scenarios.tests
    }

    fun getDisambiguationTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.disambiguation.tests
    }
}
