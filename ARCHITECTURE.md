# Architecture Overview

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        StockTracker.app                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     SwiftUI Views                          │   │
│  │                                                            │   │
│  │  ContentView                                              │   │
│  │  ├── NavigationSplitView                                 │   │
│  │  │   ├── StockListView                                   │   │
│  │  │   │   ├── StockRowView (x N) + SparklineView         │   │
│  │  │   │   └── StatusBar                                   │   │
│  │  │   └── StockDetailView / EmptyDetailView               │   │
│  │  └── AddStockView (sheet)                                │   │
│  └─────────────────────┬────────────────────────────────────┘   │
│                         │ @ObservedObject / @StateObject          │
│  ┌──────────────────────▼────────────────────────────────────┐   │
│  │               StockListViewModel (@MainActor)              │   │
│  │                                                            │   │
│  │  @Published stocks: [Stock]                               │   │
│  │  @Published selectedStock: Stock?                         │   │
│  │  @Published isInitialLoading / isRefreshing / error       │   │
│  │  @Published lastUpdated: Date?                            │   │
│  │                                                            │   │
│  │  - 15s auto-refresh timer (Task-based)                    │   │
│  │  - Concurrent quote + sparkline fetch (async let)         │   │
│  └──────┬────────────────────────┬─────────────────────────┘   │
│          │                        │                               │
│  ┌───────▼──────────┐   ┌────────▼──────────────────────────┐   │
│  │  WatchlistStore   │   │       YahooFinanceService (actor)  │   │
│  │                   │   │                                    │   │
│  │  UserDefaults I/O │   │  - Crumb-based auth               │   │
│  │  @Published       │   │  - fetchQuotes([String])           │   │
│  │  symbols: [String]│   │  - fetchSparklines([String])       │   │
│  │  - add/remove     │   │  - validateSymbol(String)          │   │
│  │  - persist/load   │   │  - Auto-retry on 401/403           │   │
│  └───────────────────┘   └────────────────┬───────────────────┘   │
│                                            │                       │
│                             Yahoo Finance API (HTTPS)              │
│                             query1.finance.yahoo.com               │
└─────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

### StockTrackerApp
- App entry point (`@main`)
- Defines the main window scene with min/default size
- Removes the default "New Item" menu command

### ContentView
- Root view composing NavigationSplitView
- Owns the `@StateObject` ViewModel (single source of truth)
- Controls sheet presentation for AddStockView

### StockListView
- Renders the sidebar list column
- Handles toolbar (refresh button, add button, refresh indicator)
- Renders three states: loading, empty, populated list
- Status bar shows last update time, gainer/loser counts, errors

### StockRowView
- Renders a single stock row: symbol, name, sparkline, price, change%
- Price flash animation on price change (green up, red down)
- Market state badges (PRE, AH, CLOSED)

### StockDetailView
- Full detail panel for selected stock
- Header: symbol, name, price, change, market state
- Today's sparkline chart (larger, 2px line)
- Key statistics grid (open, high, low, volume, market cap, prev close)
- 52-week range slider with current price indicator

### SparklineView
- Reusable mini-chart component
- Renders gradient fill + line from `[Double]` price array
- Adapts color based on `isPositive` flag
- Configurable `lineWidth` for row vs detail usage

### AddStockView
- Sheet UI for adding stocks
- Live validation via `YahooFinanceService.validateSymbol()`
- Popular tickers grid for quick adds
- Dimmed buttons for already-watchlisted stocks

### StockListViewModel (`@MainActor`)
- Single ViewModel for the entire app (scoped to ContentView)
- Manages `[Stock]` array in watchlist order
- Drives 15-second auto-refresh loop via cancellable Task
- Concurrent fetch: `async let quotes + sparklines` run in parallel
- Guards against concurrent refreshes with `isFetching` flag
- Syncs `selectedStock` after each refresh

### YahooFinanceService (`actor`)
- Thread-safe via actor isolation
- Manages crumb lifecycle (fetch, cache 30 min, auto-refresh on 401/403)
- `fetchQuotes`: Yahoo Finance v7/finance/quote
- `fetchSparklines`: Yahoo Finance v8/finance/spark
- `validateSymbol`: Lightweight symbol existence check
- Sparkline failures are non-fatal (returns empty dict)

### WatchlistStore
- Singleton `ObservableObject` for UserDefaults persistence
- Source of truth for symbol list ordering
- Publishes `symbols: [String]` for reactive consumption
- Default watchlist: AAPL, MSFT, GOOGL, AMZN, NVDA

## Data Flow

### App Launch
```
StockTrackerApp → ContentView → StockListViewModel.init()
  → stocks = store.symbols.map { Stock(symbol: $0) }  // skeleton stocks
  → Task { await startAutoRefresh() }
    → refresh()
      → YahooFinanceService.fetchQuotes() + fetchSparklines() [parallel]
      → Update stocks[] with live data
      → Publish to views via @Published
```

### Price Refresh (every 15s)
```
timerTask (background Task)
  → await refresh()
    → service.fetchQuotes(symbols) [async]
    → service.fetchSparklines(symbols) [async]
    → withAnimation { stocks = updated }  // smooth transition
    → lastUpdated = Date()
```

### Add Stock
```
User types symbol → AddStockView.submit()
  → viewModel.addStock(symbol)
    → service.validateSymbol(symbol)  // network check
    → store.add(symbol)               // persist
    → stocks.append(Stock(symbol))    // optimistic UI
    → refresh()                       // fetch live data
```

### Remove Stock
```
User right-click → Remove
  → viewModel.removeStock(symbol)
    → store.remove(symbol)            // persist
    → withAnimation { stocks.remove } // animated removal
    → selectedStock = nil if removed
```

## State Management

| State | Location | Persistence |
|-------|----------|------------|
| Watchlist symbols | WatchlistStore | UserDefaults |
| Live stock data | StockListViewModel.stocks | In-memory only |
| Selected stock | StockListViewModel.selectedStock | Session only |
| Loading/error | StockListViewModel | Session only |
| Last updated | StockListViewModel | Session only |
| Crumb token | YahooFinanceService | In-memory, 30min TTL |

## Async / Concurrency Model

- **YahooFinanceService**: `actor` — all methods are automatically isolated, preventing data races on crumb state
- **StockListViewModel**: `@MainActor` — all state updates happen on main thread, safe for SwiftUI
- **Parallel fetching**: `async let quotes + sparklines` runs both HTTP requests concurrently
- **Refresh guard**: `isFetching: Bool` (non-published, MainActor-isolated) prevents overlapping refreshes
- **Timer**: `Task { while !Task.isCancelled { sleep; refresh } }` — cancellable, no DispatchQueue timers

## Error Handling Strategy

| Error | Behavior |
|-------|----------|
| Network timeout | Shows error in status bar; next auto-refresh retries |
| 401/403 (crumb expired) | Auto-refresh crumb and retry once |
| 429 (rate limited) | Shows "rate limited" in status bar |
| Invalid symbol | Shown in AddStockView inline; not added to watchlist |
| Sparkline failure | Silent — sparkline column stays empty, quotes still shown |
| No data returned | Shows "No data available" in status bar |

## Extension Points

- **Portfolio tracking**: Add `shares: Double` and `costBasis: Double` to `Stock`, show P&L column
- **Price alerts**: Add `alertPrice: Double?` to `Stock`, use UNUserNotificationCenter
- **Multiple watchlists**: Replace `WatchlistStore.symbols: [String]` with `[Watchlist]`
- **Charting**: Replace SparklineView with full chart using Swift Charts (iOS 16+/macOS 13+)
- **Additional data sources**: Add a protocol `StockDataProvider` and inject alternatives
- **Menu bar extra**: Add `MenuBarExtra` scene to `StockTrackerApp`
