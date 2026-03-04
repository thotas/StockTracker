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
        case .rateLimited:         "Rate limited — retrying shortly"
        case .noData:              "No data available"
        }
    }
}

actor YahooFinanceService {
    static let shared = YahooFinanceService()

    private let session: URLSession
    private let decoder = JSONDecoder()
    private var crumb: String?
    private var lastCrumbFetch: Date?
    // Prevents concurrent crumb refreshes from doubling up
    private var crumbRefreshTask: Task<String, Error>?

    private static let quoteFields = [
        "regularMarketPrice", "regularMarketPreviousClose",
        "regularMarketChange", "regularMarketChangePercent",
        "regularMarketVolume", "marketCap", "regularMarketOpen",
        "regularMarketDayHigh", "regularMarketDayLow",
        "fiftyTwoWeekHigh", "fiftyTwoWeekLow",
        "shortName", "longName", "currency", "marketState"
    ].joined(separator: ",")

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            "Accept": "application/json,text/html,*/*",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        session = URLSession(configuration: config)
    }

    // MARK: - Crumb (coalesced — concurrent callers share one refresh Task)

    private func ensureCrumb() async throws -> String {
        if let crumb, let fetchDate = lastCrumbFetch,
           Date().timeIntervalSince(fetchDate) < 1800 {
            return crumb
        }
        return try await coalescedCrumbRefresh()
    }

    private func coalescedCrumbRefresh() async throws -> String {
        if let existing = crumbRefreshTask {
            return try await existing.value
        }
        let task = Task<String, Error> {
            defer { crumbRefreshTask = nil }
            return try await self.doRefreshCrumb()
        }
        crumbRefreshTask = task
        return try await task.value
    }

    private func doRefreshCrumb() async throws -> String {
        _ = try? await session.data(from: URL(string: "https://finance.yahoo.com/")!)

        let (data, response) = try await session.data(from:
            URL(string: "https://query1.finance.yahoo.com/v1/test/getcrumb")!)

        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            throw StockError.rateLimited
        }

        let fetched = String(data: data, encoding: .utf8) ?? ""
        guard !fetched.isEmpty, !fetched.contains("<") else { return "" }

        self.crumb = fetched
        self.lastCrumbFetch = Date()
        return fetched
    }

    // MARK: - Public API

    func fetchQuotes(symbols: [String]) async throws -> [String: QuoteAPIResponse.QuoteData] {
        guard !symbols.isEmpty else { return [:] }

        let crumb = (try? await ensureCrumb()) ?? ""
        let url = quoteURL(symbols: symbols, crumb: crumb)

        let (data, response) = try await session.data(for: urlRequest(url))

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200: break
            case 401, 403:
                // Invalidate crumb and retry once with fresh one
                self.crumb = nil
                let freshCrumb = (try? await coalescedCrumbRefresh()) ?? ""
                let retryURL = quoteURL(symbols: symbols, crumb: freshCrumb)
                let (retryData, _) = try await session.data(for: urlRequest(retryURL))
                return try parseQuotes(data: retryData)
            case 429: throw StockError.rateLimited
            default:  throw StockError.invalidResponse
            }
        }

        return try parseQuotes(data: data)
    }

    private func quoteURL(symbols: [String], crumb: String) -> URL {
        var comps = URLComponents(string: "https://query1.finance.yahoo.com/v7/finance/quote")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
            URLQueryItem(name: "fields", value: Self.quoteFields)
        ]
        if !crumb.isEmpty { items.append(URLQueryItem(name: "crumb", value: crumb)) }
        comps.queryItems = items
        return comps.url!
    }

    private func urlRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        return req
    }

    private func parseQuotes(data: Data) throws -> [String: QuoteAPIResponse.QuoteData] {
        let response = try decoder.decode(QuoteAPIResponse.self, from: data)
        let result = response.quoteResponse

        // Surface API-level errors
        if let apiErr = result.error, let msg = apiErr.description ?? apiErr.code {
            throw StockError.apiError(msg)
        }

        guard let results = result.result, !results.isEmpty else {
            throw StockError.noData
        }
        return Dictionary(uniqueKeysWithValues: results.map { ($0.symbol, $0) })
    }

    func fetchSparklines(symbols: [String]) async throws -> [String: [Double]] {
        guard !symbols.isEmpty else { return [:] }

        var comps = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/spark")!
        comps.queryItems = [
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
            URLQueryItem(name: "range", value: "1d"),
            URLQueryItem(name: "interval", value: "5m")
        ]
        guard let url = comps.url else { return [:] }

        guard let (data, response) = try? await session.data(for: urlRequest(url)),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else { return [:] }

        guard let sparkResp = try? decoder.decode(SparkAPIResponse.self, from: data),
              let results = sparkResp.spark.result else { return [:] }

        var map: [String: [Double]] = [:]
        for item in results {
            if let closes = item.response?.first?.indicators?.quote?.first?.close {
                let valid = closes.compactMap { $0 }
                if !valid.isEmpty { map[item.symbol] = valid }
            }
        }
        return map
    }

    func validateSymbol(_ symbol: String) async -> Bool {
        guard let result = try? await fetchQuotes(symbols: [symbol]) else { return false }
        return result[symbol.uppercased()] != nil
    }
}
