//
//  SharedTestDataLoader.swift
//  JustSpentTests
//
//  Loader for shared test data from JSON files
//  Loads test data from shared/test-data/ directory
//

import Foundation

/// Loader for shared test data
class SharedTestDataLoader {

    // MARK: - Voice Test Data Structures

    struct VoiceTestData: Codable {
        let version: String
        let description: String
        let test_suites: TestSuites
    }

    struct TestSuites: Codable {
        let currency_detection: TestSuite
        let amount_extraction: TestSuite
        let written_numbers: TestSuite
        let real_world_scenarios: TestSuite
        let edge_cases: TestSuite
        let symbol_normalization: TestSuite
        let disambiguation: TestSuite
    }

    struct TestSuite: Codable {
        let description: String
        let tests: [VoiceTestCase]
    }

    struct VoiceTestCase: Codable {
        let id: String
        let input: String
        let expected_currency: String?
        let expected_amount: Double?
        let expected_category: String?
        let expected_merchant: String?
        let description: String
        let default_currency: String?
        let normalized_output: String?
        let expected_behavior: String?
        let note: String?
    }

    // MARK: - Loading Methods

    /// Load voice test data from JSON
    static func loadVoiceTestData() throws -> VoiceTestData {
        // Try multiple possible paths for the JSON file
        let possiblePaths = [
            // Path 1: Relative from current directory
            "../../shared/test-data/voice-test-data.json",
            // Path 2: Relative from project root
            "../../../shared/test-data/voice-test-data.json",
            // Path 3: Absolute from FileManager current directory
            "\(FileManager.default.currentDirectoryPath)/../../shared/test-data/voice-test-data.json",
            // Path 4: From source root (for CI environments)
            "/home/user/just-spent/shared/test-data/voice-test-data.json",
            // Path 5: From runner work directory (GitHub Actions)
            "/home/runner/work/just-spent/just-spent/shared/test-data/voice-test-data.json"
        ]

        var lastError: Error?
        for path in possiblePaths {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let decoder = JSONDecoder()
                return try decoder.decode(VoiceTestData.self, from: data)
            }
        }

        // If none of the paths worked, throw error with all attempted paths
        let attemptedPaths = possiblePaths.joined(separator: "\n  - ")
        throw TestDataError.fileNotFound("Attempted paths:\n  - \(attemptedPaths)")
    }

    /// Get currency detection tests
    static func getCurrencyDetectionTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.currency_detection.tests
    }

    /// Get amount extraction tests
    static func getAmountExtractionTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.amount_extraction.tests
    }

    /// Get written number tests
    static func getWrittenNumberTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.written_numbers.tests
    }

    /// Get edge case tests
    static func getEdgeCaseTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.edge_cases.tests
    }

    /// Get real world scenario tests
    static func getRealWorldTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.real_world_scenarios.tests
    }

    /// Get disambiguation tests
    static func getDisambiguationTests() throws -> [VoiceTestCase] {
        let data = try loadVoiceTestData()
        return data.test_suites.disambiguation.tests
    }
}

// MARK: - Errors

enum TestDataError: Error {
    case fileNotFound(String)
    case decodingFailed(Error)

    var localizedDescription: String {
        switch self {
        case .fileNotFound(let path):
            return "Test data file not found at: \(path)"
        case .decodingFailed(let error):
            return "Failed to decode test data: \(error.localizedDescription)"
        }
    }
}
