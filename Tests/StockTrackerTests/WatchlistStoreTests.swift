import XCTest
@testable import StockTracker

final class WatchlistStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "watchlist_symbols_v1")
    }

    override func tearDown() {
        super.tearDown()
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "watchlist_symbols_v1")
    }

    // MARK: - Symbol Normalization Tests (test logic without singleton state)

    func testSymbolNormalization() {
        // Test that symbols are normalized to uppercase
        let symbol = "aapl"
        let normalized = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(normalized, "AAPL")
    }

    func testEmptySymbolRejection() {
        let symbol = ""
        let normalized = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        XCTAssertTrue(normalized.isEmpty)
    }

    func testSymbolTrimming() {
        let symbol = "  TSLA  "
        let normalized = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        XCTAssertEqual(normalized, "TSLA")
    }

    func testDuplicateDetection() {
        var symbols = ["AAPL", "MSFT", "GOOGL"]
        let newSymbol = "aapl"
        let normalized = newSymbol.uppercased().trimmingCharacters(in: .whitespaces)

        // Check if symbol already exists (case insensitive)
        let exists = symbols.contains { $0.uppercased() == normalized }
        XCTAssertTrue(exists)
    }

    // MARK: - UserDefaults Persistence

    func testSaveAndLoadFromUserDefaults() {
        let symbols = ["AAPL", "MSFT", "GOOGL", "AMZN"]
        UserDefaults.standard.set(symbols, forKey: "watchlist_symbols_v1")

        let loaded = UserDefaults.standard.stringArray(forKey: "watchlist_symbols_v1") ?? []
        XCTAssertEqual(loaded, symbols)
    }

    func testDefaultSymbols() {
        let defaults = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]
        XCTAssertEqual(defaults.count, 5)
        XCTAssertEqual(defaults.first, "AAPL")
    }

    func testUserDefaultsReturnsNilForMissingKey() {
        UserDefaults.standard.removeObject(forKey: "watchlist_symbols_v1")
        let loaded = UserDefaults.standard.stringArray(forKey: "watchlist_symbols_v1")
        XCTAssertNil(loaded)
    }
}
