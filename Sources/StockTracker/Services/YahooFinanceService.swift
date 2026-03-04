import Foundation

enum StockError: LocalizedError {
    case invalidSymbol(String)
    case networkError(Error)
    case apiError(String)
    case invalidResponse
    case rateLimited
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidSymbol(let s): "Invalid symbol: \(s)"
        case .networkError(let e): "Network: \(e.localizedDescription)"
        case .apiError(let msg):   "API error: \(msg)"
        case .invalidResponse:     "Invalid server response"
        case .rateLimited:         "Rate limited — will retry"
        case .noData:              "No data available"
        }
    }
}

// MARK: - YahooFinanceService
// Uses Yahoo Finance v8/finance/chart endpoint.
// One request per symbol returns both live quote data AND intraday sparkline.
// No crumb/auth required — only a valid Referer header.
// Symbols fetched concurrently via TaskGroup.

actor YahooFinanceService {
    static let shared = YahooFinanceService()

    private let session: URLSession
    private let decoder = JSONDecoder()

    // Base headers that make Yahoo Finance respond correctly
    private static let baseHeaders: [String: String] = [
        "User-Agent":      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
        "Accept":          "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        "Origin":          "https://finance.yahoo.com"
    ]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        // Persist cookies across requests (important for Yahoo Finance session)
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpAdditionalHeaders = Self.baseHeaders
        session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Fetch live quotes + sparkline for all symbols concurrently.
    /// Returns a dict keyed by symbol.
    func fetchAllCharts(symbols: [String]) async throws -> [String: ChartAPIResponse.ChartData] {
        guard !symbols.isEmpty else { return [:] }

        return try await withThrowingTaskGroup(of: (String, ChartAPIResponse.ChartData?).self) { group in
            for symbol in symbols {
                group.addTask { [self] in
                    let data = try? await self.fetchChart(symbol: symbol)
                    return (symbol, data)
                }
            }

            var results: [String: ChartAPIResponse.ChartData] = [:]
            for try await (symbol, data) in group {
                if let data { results[symbol] = data }
            }
            return results
        }
    }

    /// Fetch chart data for a single symbol.
    /// Endpoint: v8/finance/chart/{symbol}?interval=5m&range=1d
    func fetchChart(symbol: String) async throws -> ChartAPIResponse.ChartData {
        let url = chartURL(for: symbol)
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Symbol-specific Referer is the key to bypassing Yahoo's bot detection
        request.setValue("https://finance.yahoo.com/quote/\(symbol)/", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200:   break
            case 429:   throw StockError.rateLimited
            case 404:   throw StockError.invalidSymbol(symbol)
            default:    throw StockError.invalidResponse
            }
        }

        let parsed = try decoder.decode(ChartAPIResponse.self, from: data)

        if let err = parsed.chart.error {
            throw StockError.apiError(err.description ?? err.code ?? "Unknown API error")
        }

        guard let result = parsed.chart.result?.first else {
            throw StockError.noData
        }

        return result
    }

    /// Validate a symbol by attempting a chart fetch.
    func validateSymbol(_ symbol: String) async -> Bool {
        (try? await fetchChart(symbol: symbol.uppercased())) != nil
    }

    // MARK: - Private

    private func chartURL(for symbol: String) -> URL {
        var comps = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)")!
        comps.queryItems = [
            URLQueryItem(name: "interval", value: "5m"),
            URLQueryItem(name: "range",    value: "1d"),
            URLQueryItem(name: "includePrePost", value: "true")
        ]
        return comps.url!
    }
}
