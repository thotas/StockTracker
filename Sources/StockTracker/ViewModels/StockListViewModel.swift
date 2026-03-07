import Foundation
import SwiftUI
import Combine

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable {
    case symbol = "Symbol"
    case price = "Price"
    case changePercent = "Change %"
    case gainers = "Gainers"
    case losers = "Losers"

    var id: String { rawValue }
}

@MainActor
final class StockListViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var selectedStock: Stock?
    @Published var retryCountdown: Int = 0

    // Portfolio Mode
    @Published var isPortfolioMode = false
    let portfolioStore = PortfolioStore.shared

    // Search & Filter
    @Published var searchText = ""

    // Sorting
    @Published var sortOption: SortOption = .symbol

    private let service = YahooFinanceService.shared
    let store = WatchlistStore.shared
    private let settings = SettingsManager.shared
    private var isFetching = false
    private var isAutoRefreshRunning = false
    private var timerTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Cached formatter — not re-allocated on every status bar render
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    /// Current refresh interval from settings
    var refreshInterval: TimeInterval {
        settings.refreshInterval
    }

    /// Whether animations are enabled
    var animationsEnabled: Bool {
        settings.animationsEnabled
    }

    init() {
        stocks = store.symbols.map { Stock(symbol: $0) }

        // Listen for settings changes to restart auto-refresh with new interval
        settings.$refreshInterval
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.restartAutoRefresh()
                }
            }
            .store(in: &cancellables)

        // Listen for watchlist changes
        store.$currentWatchlistId
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.reloadForWatchlistChange()
                }
            }
            .store(in: &cancellables)

        Task { await startAutoRefresh() }
    }

    private func reloadForWatchlistChange() {
        stocks = store.symbols.map { Stock(symbol: $0) }
        selectedStock = nil
        Task { await refresh() }
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

    /// Restart auto-refresh with new settings
    func restartAutoRefresh() async {
        timerTask?.cancel()
        isAutoRefreshRunning = false
        await startAutoRefresh()
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
            // Single concurrent fetch: v8/finance/chart returns quotes + sparkline per symbol
            let charts = try await service.fetchAllCharts(symbols: symbols)

            var updated: [Stock] = []
            for symbol in symbols {
                var stock = stocks.first(where: { $0.symbol == symbol }) ?? Stock(symbol: symbol)

                if let chart = charts[symbol] {
                    let meta = chart.meta
                    let prevClose = meta.prevClose
                    let price = meta.regularMarketPrice ?? stock.price
                    let change = prevClose > 0 ? (price - prevClose) : stock.change
                    let changePct = prevClose > 0 ? (change / prevClose * 100) : stock.changePercent

                    stock.name = meta.shortName ?? meta.longName ?? symbol
                    stock.price = price
                    stock.previousClose = prevClose > 0 ? prevClose : stock.previousClose
                    stock.change = change
                    stock.changePercent = changePct
                    stock.volume = meta.regularMarketVolume ?? stock.volume
                    stock.marketCap = meta.marketCap ?? stock.marketCap
                    stock.open = meta.regularMarketOpen ?? stock.open
                    stock.high = meta.regularMarketDayHigh ?? stock.high
                    stock.low = meta.regularMarketDayLow ?? stock.low
                    stock.weekHigh52 = meta.fiftyTwoWeekHigh ?? stock.weekHigh52
                    stock.weekLow52 = meta.fiftyTwoWeekLow ?? stock.weekLow52
                    stock.currency = meta.currency ?? stock.currency
                    stock.marketState = Stock.MarketState(rawValue: meta.marketState ?? "") ?? .regular
                    stock.lastUpdated = Date()

                    let sparkline = chart.sparklineData
                    if !sparkline.isEmpty { stock.sparklineData = sparkline }
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
            // Start countdown for retry
            startRetryCountdown()
        }
    }

    // MARK: - Retry Countdown

    private func startRetryCountdown() {
        countdownTask?.cancel()
        retryCountdown = 5

        countdownTask = Task { [weak self] in
            while !Task.isCancelled && (self?.retryCountdown ?? 0) > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    if self?.retryCountdown ?? 0 > 0 {
                        self?.retryCountdown -= 1
                    }
                }
            }
            // Auto-refresh when countdown reaches 0
            if !Task.isCancelled {
                await self?.refresh()
            }
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

    // MARK: - Search & Filter

    var filteredStocks: [Stock] {
        let searchTerm = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !searchTerm.isEmpty else { return stocks }
        return stocks.filter {
            $0.symbol.lowercased().contains(searchTerm) ||
            $0.name.lowercased().contains(searchTerm)
        }
    }

    var sortedStocks: [Stock] {
        var result = isPortfolioMode ? portfolioStocks : filteredStocks

        switch sortOption {
        case .symbol:
            result.sort { $0.symbol < $1.symbol }
        case .price:
            result.sort { $0.price > $1.price }
        case .changePercent:
            result.sort { $0.changePercent > $1.changePercent }
        case .gainers:
            result.sort { $0.changePercent > $1.changePercent }
        case .losers:
            result.sort { $0.changePercent < $1.changePercent }
        }

        // For gainers/losers, filter to only show positive/negative
        if sortOption == .gainers {
            result = result.filter { $0.changePercent > 0 }
        } else if sortOption == .losers {
            result = result.filter { $0.changePercent < 0 }
        }

        return result
    }

    // MARK: - Portfolio

    var portfolioStocks: [Stock] {
        let portfolioSymbols = portfolioStore.positions.map { $0.symbol }
        return stocks.filter { portfolioSymbols.contains($0.symbol) }
    }

    var portfolioTotalValue: Double {
        portfolioStore.positions.reduce(0) { total, position in
            if let stock = stocks.first(where: { $0.symbol == position.symbol }) {
                return total + position.currentValue(price: stock.price)
            }
            return total
        }
    }

    var portfolioTotalCost: Double {
        portfolioStore.positions.reduce(0) { $0 + $1.totalCost }
    }

    var portfolioTotalProfitLoss: Double {
        portfolioTotalValue - portfolioTotalCost
    }

    var portfolioTotalProfitLossPercent: Double {
        guard portfolioTotalCost > 0 else { return 0 }
        return (portfolioTotalProfitLoss / portfolioTotalCost) * 100
    }

    var formattedPortfolioTotalValue: String {
        String(format: "$%.2f", portfolioTotalValue)
    }

    var formattedPortfolioTotalProfitLoss: String {
        let sign = portfolioTotalProfitLoss >= 0 ? "+" : ""
        return "\(sign)\(String(format: "$%.2f", portfolioTotalProfitLoss))"
    }

    var formattedPortfolioTotalProfitLossPercent: String {
        let sign = portfolioTotalProfitLossPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", portfolioTotalProfitLossPercent))%"
    }

    // MARK: - Market Status

    var marketStatus: MarketStatus {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let weekday = calendar.component(.weekday, from: now)

        // Weekend
        if weekday == 1 || weekday == 7 {
            return .closed
        }

        let currentTime = hour * 60 + minute
        let marketOpen = 9 * 60 + 30  // 9:30 AM
        let marketClose = 16 * 60     // 4:00 PM
        let preMarketStart = 4 * 60   // 4:00 AM
        let afterHoursEnd = 20 * 60  // 8:00 PM

        if currentTime >= marketOpen && currentTime < marketClose {
            return .open
        } else if currentTime >= preMarketStart && currentTime < marketOpen {
            return .preMarket
        } else if currentTime >= marketClose && currentTime < afterHoursEnd {
            return .afterHours
        } else {
            return .closed
        }
    }
}

// MARK: - Market Status

enum MarketStatus: String {
    case open = "Open"
    case closed = "Closed"
    case preMarket = "Pre-Market"
    case afterHours = "After Hours"

    var color: Color {
        switch self {
        case .open: return Color(red: 0.18, green: 0.80, blue: 0.44)
        case .closed: return .secondary
        case .preMarket: return .orange
        case .afterHours: return .purple
        }
    }

    var icon: String {
        switch self {
        case .open: return "checkmark.circle.fill"
        case .closed: return "xmark.circle.fill"
        case .preMarket: return "sunrise.fill"
        case .afterHours: return "sunset.fill"
        }
    }
}
