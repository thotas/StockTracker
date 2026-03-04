import Foundation
import SwiftUI

struct Stock: Identifiable, Equatable, Hashable {
    // id == symbol: stable across refreshes, fixes List selection identity
    let id: String
    let symbol: String
    var name: String
    var price: Double
    var previousClose: Double
    var change: Double
    var changePercent: Double
    var volume: Int64
    var marketCap: Double
    var open: Double
    var high: Double
    var low: Double
    var weekHigh52: Double
    var weekLow52: Double
    var currency: String
    var marketState: MarketState
    var sparklineData: [Double]
    var lastUpdated: Date?

    enum MarketState: String {
        case regular   = "REGULAR"
        case preMarket = "PRE"
        case postMarket = "POST"
        case closed    = "CLOSED"
        case prepre    = "PREPRE"
        case postpost  = "POSTPOST"

        var displayName: String {
            switch self {
            case .regular:              "Open"
            case .preMarket, .prepre:   "Pre-Market"
            case .postMarket, .postpost:"After Hours"
            case .closed:               "Closed"
            }
        }
    }

    // change > 0 = green, change < 0 = red, change == 0 = neutral
    var isGaining: Bool { change > 0 }
    var isLosing:  Bool { change < 0 }

    var changeColor: Color {
        if change > 0 { return Color(red: 0.18, green: 0.80, blue: 0.44) }
        if change < 0 { return Color(red: 0.95, green: 0.27, blue: 0.27) }
        return .secondary
    }

    // Legacy alias used in some views
    var isPositive: Bool { change >= 0 }

    init(symbol: String) {
        let upper = symbol.uppercased()
        self.id = upper
        self.symbol = upper
        self.name = upper
        self.price = 0
        self.previousClose = 0
        self.change = 0
        self.changePercent = 0
        self.volume = 0
        self.marketCap = 0
        self.open = 0
        self.high = 0
        self.low = 0
        self.weekHigh52 = 0
        self.weekLow52 = 0
        self.currency = "USD"
        self.marketState = .regular
        self.sparklineData = []
        self.lastUpdated = nil
    }

    var formattedPrice: String { String(format: "%.2f", price) }

    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))"
    }

    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }

    var formattedVolume: String {
        if volume >= 1_000_000_000 { return String(format: "%.2fB", Double(volume) / 1_000_000_000) }
        if volume >= 1_000_000    { return String(format: "%.2fM", Double(volume) / 1_000_000) }
        if volume >= 1_000        { return String(format: "%.1fK", Double(volume) / 1_000) }
        return "\(volume)"
    }

    var formattedMarketCap: String {
        if marketCap >= 1_000_000_000_000 { return String(format: "%.2fT", marketCap / 1_000_000_000_000) }
        if marketCap >= 1_000_000_000     { return String(format: "%.2fB", marketCap / 1_000_000_000) }
        if marketCap >= 1_000_000         { return String(format: "%.2fM", marketCap / 1_000_000) }
        return String(format: "%.0f", marketCap)
    }

    static func == (lhs: Stock, rhs: Stock) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
