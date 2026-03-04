import Foundation

// MARK: - Yahoo Finance v8/finance/chart Response
// Used for both live quotes AND sparkline data in a single request per symbol.
// Endpoint: https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}?interval=5m&range=1d
// Requires: Referer: https://finance.yahoo.com/quote/{SYMBOL}/

struct ChartAPIResponse: Decodable {
    let chart: ChartResult

    struct ChartResult: Decodable {
        let result: [ChartData]?
        let error: ChartError?
    }

    struct ChartError: Decodable {
        let code: String?
        let description: String?
    }

    struct ChartData: Decodable {
        let meta: ChartMeta
        let timestamp: [Int]?
        let indicators: Indicators?

        struct ChartMeta: Decodable {
            let symbol: String
            let currency: String?
            let shortName: String?
            let longName: String?
            let exchangeName: String?
            let regularMarketPrice: Double?
            let regularMarketOpen: Double?
            let regularMarketDayHigh: Double?
            let regularMarketDayLow: Double?
            let regularMarketVolume: Int64?
            let marketCap: Double?
            // Previous close: Yahoo uses chartPreviousClose in v8, fallback to previousClose
            let chartPreviousClose: Double?
            let previousClose: Double?
            let fiftyTwoWeekHigh: Double?
            let fiftyTwoWeekLow: Double?
            let marketState: String?

            // Derived: previous close with fallback chain
            var prevClose: Double {
                chartPreviousClose ?? previousClose ?? 0
            }
        }

        struct Indicators: Decodable {
            let quote: [Quote]?

            struct Quote: Decodable {
                let close: [Double?]?
            }
        }

        // Convenience: valid (non-nil) close prices for sparkline
        var sparklineData: [Double] {
            indicators?.quote?.first?.close?.compactMap { $0 } ?? []
        }
    }
}
