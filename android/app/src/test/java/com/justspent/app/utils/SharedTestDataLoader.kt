package com.justspent.app.utils

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.File

/**
 * Loader for shared test data from JSON files
 * Loads test data from shared/test-data/ directory
 */
object SharedTestDataLoader {

    private val gson = Gson()

    /**
     * Voice test data structure
     */
    data class VoiceTestData(
        val version: String,
        val description: String,
        val test_suites: TestSuites
    )

    data class TestSuites(
        val currency_detection: TestSuite,
        val amount_extraction: TestSuite,
        val written_numbers: TestSuite,
        val real_world_scenarios: TestSuite,
        val edge_cases: TestSuite,
        val symbol_normalization: TestSuite,
        val disambiguation: TestSuite
    )

    data class TestSuite(
        val description: String,
        val tests: List<VoiceTestCase>
    )

    data class VoiceTestCase(
        val id: String,
        val input: String,
        val expected_currency: String?,
        val expected_amount: Double?,
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
        return gson.fromJson(jsonContent, VoiceTestData::class.java)
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
