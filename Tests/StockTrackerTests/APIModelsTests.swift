import XCTest
@testable import StockTracker

final class APIModelsTests: XCTestCase {

    // MARK: - ChartAPIResponse Parsing

    func testChartAPIResponseParsing() {
        let json = """
        {
            "chart": {
                "result": [
                    {
                        "meta": {
                            "symbol": "AAPL",
                            "currency": "USD",
                            "shortName": "Apple Inc.",
                            "longName": "Apple Inc.",
                            "exchangeName": "NASDAQ",
                            "regularMarketPrice": 175.50,
                            "regularMarketOpen": 174.00,
                            "regularMarketDayHigh": 176.20,
                            "regularMarketDayLow": 173.80,
                            "regularMarketVolume": 50000000,
                            "marketCap": 2800000000000,
                            "chartPreviousClose": 174.00,
                            "previousClose": 174.00,
                            "fiftyTwoWeekHigh": 199.62,
                            "fiftyTwoWeekLow": 124.17,
                            "marketState": "REGULAR"
                        },
                        "timestamp": [1234567890, 1234567920],
                        "indicators": {
                            "quote": [
                                {
                                    "close": [174.0, 175.5]
                                }
                            ]
                        }
                    }
                ],
                "error": null
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: json)

        XCTAssertNotNil(response)
        XCTAssertNotNil(response?.chart.result)
        XCTAssertEqual(response?.chart.result?.first?.meta.symbol, "AAPL")
        XCTAssertEqual(response?.chart.result?.first?.meta.currency, "USD")
        XCTAssertEqual(response?.chart.result?.first?.meta.shortName, "Apple Inc.")
        XCTAssertEqual(response?.chart.result?.first?.meta.regularMarketPrice, 175.50)
        XCTAssertEqual(response?.chart.result?.first?.meta.regularMarketOpen, 174.00)
        XCTAssertEqual(response?.chart.result?.first?.meta.regularMarketDayHigh, 176.20)
        XCTAssertEqual(response?.chart.result?.first?.meta.regularMarketDayLow, 173.80)
        XCTAssertEqual(response?.chart.result?.first?.meta.regularMarketVolume, 50000000)
        XCTAssertEqual(response?.chart.result?.first?.meta.marketCap, 2800000000000)
        XCTAssertEqual(response?.chart.result?.first?.meta.fiftyTwoWeekHigh, 199.62)
        XCTAssertEqual(response?.chart.result?.first?.meta.fiftyTwoWeekLow, 124.17)
        XCTAssertEqual(response?.chart.result?.first?.meta.marketState, "REGULAR")
    }

    func testChartAPIResponsePrevCloseFallback() {
        let jsonWithChartPreviousClose = """
        {
            "chart": {
                "result": [{
                    "meta": {
                        "symbol": "AAPL",
                        "chartPreviousClose": 174.00,
                        "regularMarketPrice": 175.50
                    }
                }]
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: jsonWithChartPreviousClose)
        XCTAssertEqual(response?.chart.result?.first?.meta.prevClose, 174.00)

        let jsonWithPreviousClose = """
        {
            "chart": {
                "result": [{
                    "meta": {
                        "symbol": "AAPL",
                        "previousClose": 173.50,
                        "regularMarketPrice": 175.50
                    }
                }]
            }
        }
        """.data(using: .utf8)!

        let response2 = try? JSONDecoder().decode(ChartAPIResponse.self, from: jsonWithPreviousClose)
        XCTAssertEqual(response2?.chart.result?.first?.meta.prevClose, 173.50)
    }

    func testSparklineDataExtraction() {
        let json = """
        {
            "chart": {
                "result": [{
                    "meta": { "symbol": "AAPL" },
                    "indicators": {
                        "quote": [{
                            "close": [100.0, 101.5, 102.0, 103.2, 104.5]
                        }]
                    }
                }]
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: json)
        let sparkline = response?.chart.result?.first?.sparklineData ?? []

        XCTAssertEqual(sparkline.count, 5)
        XCTAssertEqual(sparkline[0], 100.0)
        XCTAssertEqual(sparkline[4], 104.5)
    }

    func testSparklineDataEmptyWhenNoQuote() {
        let json = """
        {
            "chart": {
                "result": [{
                    "meta": { "symbol": "AAPL" }
                }]
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: json)
        let sparkline = response?.chart.result?.first?.sparklineData ?? []

        XCTAssertTrue(sparkline.isEmpty)
    }

    func testErrorResponse() {
        let json = """
        {
            "chart": {
                "result": null,
                "error": {
                    "code": "Not Found",
                    "description": "Symbol not found"
                }
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: json)

        XCTAssertNotNil(response?.chart.error)
        XCTAssertEqual(response?.chart.error?.code, "Not Found")
        XCTAssertEqual(response?.chart.error?.description, "Symbol not found")
    }

    func testNoResultResponse() {
        let json = """
        {
            "chart": {
                "result": null,
                "error": null
            }
        }
        """.data(using: .utf8)!

        let response = try? JSONDecoder().decode(ChartAPIResponse.self, from: json)

        XCTAssertNil(response?.chart.result)
    }
}
