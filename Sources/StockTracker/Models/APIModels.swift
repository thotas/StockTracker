import Foundation

// MARK: - Quote API Response

struct QuoteAPIResponse: Decodable {
    let quoteResponse: QuoteResult

    struct QuoteResult: Decodable {
        let result: [QuoteData]?
        let error: QuoteError?
    }

    struct QuoteError: Decodable {
        let code: String?
        let description: String?
    }

    struct QuoteData: Decodable {
        let symbol: String
        let shortName: String?
        let longName: String?
        let regularMarketPrice: Double?
        let regularMarketPreviousClose: Double?
        let regularMarketChange: Double?
        let regularMarketChangePercent: Double?
        let regularMarketVolume: Int64?
        let marketCap: Double?
        let regularMarketOpen: Double?
        let regularMarketDayHigh: Double?
        let regularMarketDayLow: Double?
        let fiftyTwoWeekHigh: Double?
        let fiftyTwoWeekLow: Double?
        let currency: String?
        let marketState: String?
    }
}

// MARK: - Spark API Response

struct SparkAPIResponse: Decodable {
    let spark: SparkResult

    struct SparkResult: Decodable {
        let result: [SparkSymbol]?
    }

    struct SparkSymbol: Decodable {
        let symbol: String
        let response: [SparkData]?
    }

    struct SparkData: Decodable {
        let indicators: Indicators?

        struct Indicators: Decodable {
            let quote: [Quote]?

            struct Quote: Decodable {
                let close: [Double?]?
            }
        }
    }
}
