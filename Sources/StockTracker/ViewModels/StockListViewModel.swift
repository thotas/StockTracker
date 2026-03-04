import Foundation
import SwiftUI
import Combine

@MainActor
final class StockListViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var selectedStock: Stock?

    private let service = YahooFinanceService.shared
    private let store = WatchlistStore.shared
    private var isFetching = false
    private var isAutoRefreshRunning = false
    private var timerTask: Task<Void, Never>?

    // Cached formatter — not re-allocated on every status bar render
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    let refreshInterval: TimeInterval = 15

    init() {
        stocks = store.symbols.map { Stock(symbol: $0) }
        Task { await startAutoRefresh() }
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh() async {
        guard !isAutoRefreshRunning else { return }
        isAutoRefreshRunning = true
        timerTask?.cancel()

        await refresh()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.refreshInterval ?? 15) * 1_000_000_000))
                guard let self else { break }      // stop looping if deallocated
                guard !Task.isCancelled else { break }
                await self.refresh()
            }
        }
    }

    // MARK: - Refresh

    func refresh() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        let symbols = store.symbols
        guard !symbols.isEmpty else {
            stocks = []
            isInitialLoading = false
            isRefreshing = false
            return
        }

        let hasLiveData = stocks.contains(where: { $0.price > 0 })
        if hasLiveData { isRefreshing = true } else { isInitialLoading = true }
        error = nil

        defer {
            isInitialLoading = false
            isRefreshing = false
        }

        do {
            async let quotesTask = service.fetchQuotes(symbols: symbols)
            async let sparklinesTask = service.fetchSparklines(symbols: symbols)
            let (quotes, sparklines) = try await (quotesTask, sparklinesTask)

            var updated: [Stock] = []
            for symbol in symbols {
                // Reuse existing stock to preserve stable ID and any cached sparkline
                var stock = stocks.first(where: { $0.symbol == symbol }) ?? Stock(symbol: symbol)

                if let q = quotes[symbol] {
                    stock.name = q.shortName ?? q.longName ?? symbol
                    stock.price = q.regularMarketPrice ?? stock.price
                    stock.previousClose = q.regularMarketPreviousClose ?? stock.previousClose
                    stock.change = q.regularMarketChange ?? stock.change
                    stock.changePercent = q.regularMarketChangePercent ?? stock.changePercent
                    stock.volume = q.regularMarketVolume ?? stock.volume
                    stock.marketCap = q.marketCap ?? stock.marketCap
                    stock.open = q.regularMarketOpen ?? stock.open
                    stock.high = q.regularMarketDayHigh ?? stock.high
                    stock.low = q.regularMarketDayLow ?? stock.low
                    stock.weekHigh52 = q.fiftyTwoWeekHigh ?? stock.weekHigh52
                    stock.weekLow52 = q.fiftyTwoWeekLow ?? stock.weekLow52
                    stock.currency = q.currency ?? stock.currency
                    stock.marketState = Stock.MarketState(rawValue: q.marketState ?? "") ?? .regular
                    stock.lastUpdated = Date()
                }

                if let data = sparklines[symbol], !data.isEmpty {
                    stock.sparklineData = data
                }
                updated.append(stock)
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                self.stocks = updated
            }
            lastUpdated = Date()

            // Sync detail panel
            if let sel = selectedStock,
               let refreshed = updated.first(where: { $0.symbol == sel.symbol }) {
                selectedStock = refreshed
            }

        } catch {
            self.error = (error as? StockError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Watchlist Management

    func addStock(symbol: String) async -> Bool {
        let upper = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        guard !upper.isEmpty else { return false }
        if store.symbols.contains(upper) { return true }

        let valid = await service.validateSymbol(upper)
        guard valid else { return false }

        store.add(symbol: upper)
        stocks.append(Stock(symbol: upper))
        await refresh()
        return true
    }

    func removeStock(symbol: String) {
        store.remove(symbol: symbol)
        withAnimation {
            stocks.removeAll { $0.symbol == symbol }
        }
        if selectedStock?.symbol == symbol { selectedStock = nil }
    }

    // MARK: - Derived

    var formattedLastUpdated: String {
        guard let date = lastUpdated else { return "Never" }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    var gainers: Int { stocks.filter { $0.change > 0 && $0.price > 0 }.count }
    var losers:  Int { stocks.filter { $0.change < 0 && $0.price > 0 }.count }
}
