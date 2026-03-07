import XCTest
@testable import StockTracker

final class StockErrorTests: XCTestCase {

    func testInvalidSymbolError() {
        let error = StockError.invalidSymbol("INVALID")
        XCTAssertEqual(error.errorDescription, "Invalid symbol: INVALID")
    }

    func testNetworkError() {
        let nsError = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])
        let error = StockError.networkError(nsError)
        XCTAssertEqual(error.errorDescription, "Network: Connection failed")
    }

    func testAPIError() {
        let error = StockError.apiError("Rate limit exceeded")
        XCTAssertEqual(error.errorDescription, "API error: Rate limit exceeded")
    }

    func testInvalidResponseError() {
        let error = StockError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid server response")
    }

    func testRateLimitedError() {
        let error = StockError.rateLimited
        XCTAssertEqual(error.errorDescription, "Rate limited — will retry")
    }

    func testNoDataError() {
        let error = StockError.noData
        XCTAssertEqual(error.errorDescription, "No data available")
    }
}
