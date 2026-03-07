import XCTest
import SwiftUI
@testable import StockTracker

final class StockTests: XCTestCase {

    // MARK: - Initialization

    func testStockInitWithSymbol() {
        let stock = Stock(symbol: "AAPL")

        XCTAssertEqual(stock.id, "AAPL")
        XCTAssertEqual(stock.symbol, "AAPL")
        XCTAssertEqual(stock.name, "AAPL")
        XCTAssertEqual(stock.price, 0)
        XCTAssertEqual(stock.previousClose, 0)
        XCTAssertEqual(stock.change, 0)
        XCTAssertEqual(stock.changePercent, 0)
        XCTAssertEqual(stock.volume, 0)
        XCTAssertEqual(stock.marketCap, 0)
        XCTAssertEqual(stock.currency, "USD")
        XCTAssertEqual(stock.marketState, .regular)
        XCTAssertTrue(stock.sparklineData.isEmpty)
        XCTAssertNil(stock.lastUpdated)
    }

    func testStockInitNormalizesSymbol() {
        let stock = Stock(symbol: "aapl")
        XCTAssertEqual(stock.symbol, "AAPL")
        XCTAssertEqual(stock.id, "AAPL")
    }

    // MARK: - Computed Properties

    func testIsGaining() {
        var stock = Stock(symbol: "AAPL")
        stock.change = 1.5
        XCTAssertTrue(stock.isGaining)
        XCTAssertFalse(stock.isLosing)
    }

    func testIsLosing() {
        var stock = Stock(symbol: "AAPL")
        stock.change = -1.5
        XCTAssertTrue(stock.isLosing)
        XCTAssertFalse(stock.isGaining)
    }

    func testIsNeutral() {
        var stock = Stock(symbol: "AAPL")
        stock.change = 0
        XCTAssertFalse(stock.isGaining)
        XCTAssertFalse(stock.isLosing)
    }

    func testChangeColor() {
        var gainingStock = Stock(symbol: "AAPL")
        gainingStock.change = 5.0

        var losingStock = Stock(symbol: "GOOGL")
        losingStock.change = -5.0

        var neutralStock = Stock(symbol: "MSFT")
        neutralStock.change = 0

        XCTAssertEqual(gainingStock.changeColor, Color(red: 0.18, green: 0.80, blue: 0.44))
        XCTAssertEqual(losingStock.changeColor, Color(red: 0.95, green: 0.27, blue: 0.27))
        XCTAssertEqual(neutralStock.changeColor, .secondary)
    }

    func testIsPositiveAlias() {
        var stock = Stock(symbol: "AAPL")
        stock.change = 10.0
        XCTAssertTrue(stock.isPositive)

        stock.change = -5.0
        XCTAssertFalse(stock.isPositive)

        stock.change = 0
        XCTAssertTrue(stock.isPositive)
    }

    // MARK: - Formatting

    func testFormattedPrice() {
        var stock = Stock(symbol: "AAPL")
        stock.price = 150.25
        XCTAssertEqual(stock.formattedPrice, "150.25")
    }

    func testFormattedChange() {
        var stock = Stock(symbol: "AAPL")
        stock.change = 2.50
        XCTAssertEqual(stock.formattedChange, "+2.50")

        stock.change = -1.25
        XCTAssertEqual(stock.formattedChange, "-1.25")

        stock.change = 0
        XCTAssertEqual(stock.formattedChange, "+0.00")
    }

    func testFormattedChangePercent() {
        var stock = Stock(symbol: "AAPL")
        stock.changePercent = 1.5
        XCTAssertEqual(stock.formattedChangePercent, "+1.50%")

        stock.changePercent = -0.75
        XCTAssertEqual(stock.formattedChangePercent, "-0.75%")
    }

    func testFormattedVolume() {
        var stock = Stock(symbol: "AAPL")
        stock.volume = 1_000_000_000
        XCTAssertEqual(stock.formattedVolume, "1.00B")

        stock.volume = 52_300_000
        XCTAssertEqual(stock.formattedVolume, "52.30M")

        stock.volume = 15_500
        XCTAssertEqual(stock.formattedVolume, "15.5K")

        stock.volume = 500
        XCTAssertEqual(stock.formattedVolume, "500")
    }

    func testFormattedMarketCap() {
        var stock = Stock(symbol: "AAPL")
        stock.marketCap = 3_000_000_000_000
        XCTAssertEqual(stock.formattedMarketCap, "3.00T")

        stock.marketCap = 500_000_000_000
        XCTAssertEqual(stock.formattedMarketCap, "500.00B")

        stock.marketCap = 75_000_000
        XCTAssertEqual(stock.formattedMarketCap, "75.00M")
    }

    // MARK: - Market State

    func testMarketStateDisplayName() {
        XCTAssertEqual(Stock.MarketState.regular.displayName, "Open")
        XCTAssertEqual(Stock.MarketState.preMarket.displayName, "Pre-Market")
        XCTAssertEqual(Stock.MarketState.prepre.displayName, "Pre-Market")
        XCTAssertEqual(Stock.MarketState.postMarket.displayName, "After Hours")
        XCTAssertEqual(Stock.MarketState.postpost.displayName, "After Hours")
        XCTAssertEqual(Stock.MarketState.closed.displayName, "Closed")
    }

    // MARK: - Equatable & Hashable

    func testEquality() {
        let stock1 = Stock(symbol: "AAPL")
        var stock2 = Stock(symbol: "AAPL")
        stock2.price = 150.0

        XCTAssertEqual(stock1, stock2)
    }

    func testHash() {
        let stock1 = Stock(symbol: "AAPL")
        let stock2 = Stock(symbol: "AAPL")

        var hasher1 = Hasher()
        stock1.hash(into: &hasher1)
        let hash1 = hasher1.finalize()

        var hasher2 = Hasher()
        stock2.hash(into: &hasher2)
        let hash2 = hasher2.finalize()

        XCTAssertEqual(hash1, hash2)
    }
}
