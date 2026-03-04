# Architecture & Design Decisions

## Platform: Native macOS (SwiftUI)
- **Chosen:** SwiftUI + Swift Concurrency (macOS 14+)
- **Alternatives considered:** Electron, Tauri, web wrapper
- **Rationale:** Hard rule — desktop apps are always native macOS. SwiftUI gives us native controls, vibrancy, system materials, SF Pro, and perfect macOS integration out of the box.
- **Tradeoffs:** macOS-only. No cross-platform support, which is fine for this use case.

## Architecture Pattern: MVVM
- **Chosen:** MVVM with ObservableObject ViewModels
- **Alternatives considered:** MVC (too tight coupling in SwiftUI), TCA (overkill for this scope), plain @State (doesn't scale)
- **Rationale:** MVVM is idiomatic SwiftUI. Clean separation: Views are dumb, ViewModels hold state and business logic, Services are injected via singletons.
- **Tradeoffs:** Slight overhead for a simple app, but pays off for testability and extensibility.

## Stock Data API: Yahoo Finance (Unofficial)
- **Chosen:** Yahoo Finance v7/v8 API with crumb-based authentication
- **Alternatives considered:** Finnhub (free tier, requires API key), Alpha Vantage (slow free tier), Marketstack (limited free tier)
- **Rationale:** No API key required. Real-time prices for all major exchanges. The crumb mechanism handles auth transparently.
- **Tradeoffs:** Unofficial API — no SLA, may change without notice. Handled gracefully with error states and retry logic.

## Concurrency Model: Swift Structured Concurrency (async/await)
- **Chosen:** async/await + Task + actor isolation
- **Alternatives considered:** Combine-only, GCD, OperationQueue
- **Rationale:** Swift structured concurrency is the modern standard. Actor isolation for YahooFinanceService prevents data races. async let parallelizes quote + sparkline fetching.
- **Tradeoffs:** Requires macOS 12+, which is fine given our macOS 14 target.

## Persistence: UserDefaults
- **Chosen:** UserDefaults for watchlist symbol list
- **Alternatives considered:** CoreData (overkill), SQLite (overkill), JSON file (unnecessary complexity)
- **Rationale:** The watchlist is simply an ordered list of strings. UserDefaults is the correct tool — lightweight, reliable, instant.
- **Tradeoffs:** Not suitable for complex relational data. Acceptable here.

## Price Caching: In-Memory Only
- **Chosen:** In-memory state in StockListViewModel; no disk cache for prices
- **Alternatives considered:** Disk-persisted price cache
- **Rationale:** Stock prices are time-sensitive and stale within seconds. Caching to disk would give users false confidence in outdated data. Fresh fetch on every launch is the right behavior.
- **Tradeoffs:** First launch always shows skeleton rows until network call completes (typically < 1 second).

## Auto-Refresh: 15-Second Timer
- **Chosen:** Repeating Task with 15-second interval
- **Alternatives considered:** WebSocket streaming (Yahoo Finance doesn't support it), 5-second polling (too aggressive for unofficial API), 60-second polling (too stale)
- **Rationale:** 15 seconds balances freshness with API courtesy. Prices are quoted in real-time anyway so sub-15s granularity rarely matters for a watchlist.
- **Tradeoffs:** Not true real-time. Prices can be up to 15 seconds delayed between refreshes.

## Layout: NavigationSplitView
- **Chosen:** Two-column NavigationSplitView (sidebar list + detail panel)
- **Alternatives considered:** Single-column list, tabbed interface
- **Rationale:** NavigationSplitView is the Apple-recommended pattern for macOS data browsers. Users can see the list and detail simultaneously, which is the primary use case for a stock tracker.
- **Tradeoffs:** Uses more horizontal space. Minimum window width is 720px.

## Color Scheme: Dark Mode First
- **Chosen:** System adaptive (supports both dark and light), dark is the primary design target
- **Alternatives considered:** Force dark only, light only
- **Rationale:** Financial apps are traditionally viewed in low-light environments (trading terminals, evening sessions). Dark mode reduces eye strain.
- **Tradeoffs:** Both modes are supported via NSColor system colors, so no real tradeoff.

## Sparkline Data: Yahoo Finance Spark API (1d, 5m intervals)
- **Chosen:** v8/finance/spark with 1-day range and 5-minute intervals
- **Alternatives considered:** Historical data (too slow), intraday tick data (too granular)
- **Rationale:** The spark endpoint is purpose-built for mini-charts. 1-day range with 5-minute candles gives ~78 data points — enough for a meaningful trend line.
- **Tradeoffs:** Sparklines may lag real-time price by a few minutes.
