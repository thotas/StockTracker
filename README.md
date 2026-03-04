# StockTracker

> A native macOS app for tracking live stock prices with real-time updates, sparkline charts, and a clean dark-first interface.

```
┌─────────────────────────────────────────────────────────────────────┐
│ 🔵 StockTracker               ⟳  +                                 │
├────────────────────────┬────────────────────────────────────────────┤
│ Watchlist              │  AAPL                                      │
│                        │  Apple Inc.                                │
│ AAPL  Apple Inc.       │                                            │
│ ████  $192.53  +1.24%  │  USD  192.53                ▲ +2.31 +1.22%│
│                        │  ● Open  ·  3:47 PM                        │
│ MSFT  Microsoft        │                                            │
│ ████  $415.20  +0.83%  │  [████████████████████] Today              │
│                        │                                            │
│ GOOGL Alphabet         │  Key Statistics                            │
│ ████  $175.08  -0.41%  │  ┌──────────┐ ┌──────────┐               │
│                        │  │ Open     │ │ Volume   │               │
│ AMZN  Amazon           │  │ 190.10   │ │ 54.2M    │               │
│ ████  $228.15  +2.10%  │  ├──────────┤ ├──────────┤               │
│                        │  │ Day High │ │ Mkt Cap  │               │
│ NVDA  NVIDIA           │  │ 193.04   │ │ 2.94T    │               │
│ ████  $950.02  +4.33%  │  └──────────┘ └──────────┘               │
│                        │                                            │
│ ▲4 ▼1  · Updated 3s ago│  52-Week Range  ●────────────────         │
└────────────────────────┴────────────────────────────────────────────┘
```

## What It Does

StockTracker is a lightweight macOS menubar-style companion for monitoring your stock watchlist. It fetches live quotes from Yahoo Finance every 15 seconds and displays them in a clean two-panel layout — watchlist on the left, full detail on the right.

- **Live prices** with automatic 15-second refresh
- **Sparkline mini-charts** showing today's intraday price movement
- **Color-coded change indicators** — green for gains, red for losses
- **Price flash animation** when a value changes on refresh
- **Market state badges** — Pre-Market, After Hours, Closed
- **Full detail panel** — open, high, low, volume, market cap, 52-week range slider
- **Add/remove stocks** with instant Yahoo Finance symbol validation
- **Persistent watchlist** — your symbols survive app restarts
- **Dark mode first**, adapts to system appearance

## Why It Exists

Most stock apps are either bloated (Bloomberg Terminal, Webull) or mobile-first (Robinhood). StockTracker is a focused macOS-native tool for quickly glancing at prices while you work — no accounts, no ads, no clutter.

## Features

- [x] Live stock quotes (equities, ETFs, indices)
- [x] Intraday sparkline charts per stock
- [x] Real-time price flash on update
- [x] NavigationSplitView: list + detail simultaneously
- [x] Add stocks with symbol validation
- [x] Remove stocks via right-click context menu
- [x] 52-week range slider with price indicator
- [x] Gainer/loser count in status bar
- [x] Market state display (Open / Pre-Market / After Hours / Closed)
- [x] Error handling with status bar messaging
- [x] Persistent watchlist via UserDefaults

## Tech Stack

| Technology | Why |
|---|---|
| **SwiftUI** | Native macOS UI, system controls, vibrancy, proper dark mode |
| **Swift Concurrency** | async/await + actor isolation for safe, clean async code |
| **Yahoo Finance API** | Free, no API key, real-time quotes for all major exchanges |
| **UserDefaults** | Watchlist persistence — simple key-value is all we need |
| **Swift Package Manager** | Zero config build system, no Xcode project file needed |

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+ **or** Swift 5.9+ toolchain
- Internet connection (for live quotes)

Install Swift if needed:
```bash
xcode-select --install
```

## Installation

```bash
# Clone the repo
git clone https://github.com/thotas/StockTracker.git
cd StockTracker
```

## How to Run

```bash
swift run
```

The app will launch as a native macOS window. On first launch it fetches live prices for the default watchlist (AAPL, MSFT, GOOGL, AMZN, NVDA).

**Or open in Xcode:**
```bash
open Package.swift
```
Then press ⌘R to run.

## Configuration

No configuration files required. All settings are managed in-app:

| Setting | How to change |
|---|---|
| Watchlist symbols | Click **+** to add, right-click → Remove to delete |
| Refresh interval | Edit `refreshInterval` in `StockListViewModel.swift` (default: 15s) |
| Default symbols | Edit `defaults` in `WatchlistStore.swift` |

## Architecture

```
StockTrackerApp (@main)
└── ContentView (@StateObject StockListViewModel)
    ├── StockListView          — watchlist sidebar
    │   └── StockRowView       — symbol, sparkline, price, change%
    └── StockDetailView        — charts, stats, 52-week range

StockListViewModel (@MainActor)
├── YahooFinanceService (actor) — HTTP, crumb auth, quote + sparkline fetch
└── WatchlistStore             — UserDefaults persistence
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the full technical reference.

## Folder Structure

```
StockTracker/
├── Package.swift                         # SPM build config (macOS 14 target)
├── Sources/StockTracker/
│   ├── StockTrackerApp.swift             # @main entry point, scene config
│   ├── Models/
│   │   ├── Stock.swift                   # Core domain model
│   │   └── APIModels.swift               # Decodable API response types
│   ├── Services/
│   │   ├── YahooFinanceService.swift     # All Yahoo Finance API calls
│   │   └── WatchlistStore.swift         # UserDefaults persistence
│   ├── ViewModels/
│   │   └── StockListViewModel.swift     # State, refresh timer, business logic
│   └── Views/
│       ├── ContentView.swift             # Root NavigationSplitView
│       ├── StockListView.swift           # Sidebar: list + toolbar + status
│       ├── StockRowView.swift            # One row: symbol, sparkline, price
│       ├── StockDetailView.swift         # Detail: chart, stats, range
│       ├── AddStockView.swift            # Add stock sheet with validation
│       └── SparklineView.swift          # Reusable mini price chart
├── README.md
├── DECISIONS.md                          # Every major design decision
└── ARCHITECTURE.md                       # System diagram and component docs
```

## Known Limitations

- **Unofficial API**: Yahoo Finance's API is unofficial and may change. If quotes stop loading, the crumb/auth flow may need updating.
- **No streaming**: Prices refresh every 15 seconds, not tick-by-tick.
- **No historical charts**: Only today's intraday sparkline is shown. Full charting would require Swift Charts integration.
- **No portfolio tracking**: No shares or cost basis — this is a price tracker, not a portfolio manager.
- **Delayed quotes**: Yahoo Finance free quotes may be delayed up to 15 minutes for some exchanges (typically real-time for US equities).
- **macOS only**: Native SwiftUI — no iOS/iPadOS version.

## Roadmap

- [ ] Menu bar extra — see prices without opening a window
- [ ] Swift Charts integration for full intraday/historical charts
- [ ] Portfolio mode — track shares, cost basis, total P&L
- [ ] Price alerts via macOS notifications
- [ ] Multiple watchlists with tab/sidebar navigation
- [ ] Currency conversion for international stocks
- [ ] Export watchlist to CSV

## License

MIT License. See LICENSE file.
