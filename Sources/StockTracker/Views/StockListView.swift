import SwiftUI

// MARK: - Focused Scene Values

struct SelectedStockKey: FocusedValueKey {
    typealias Value = String
}

extension FocusedValues {
    var selectedStockSymbol: String? {
        get { self[SelectedStockKey.self] }
        set { self[SelectedStockKey.self] = newValue }
    }
}

// MARK: - StockListView

struct StockListView: View {
    @ObservedObject var viewModel: StockListViewModel
    @Binding var showAddStock: Bool
    @Binding var showSettings: Bool
    @State private var showAddPosition = false

    var body: some View {
        VStack(spacing: 0) {
            marketStatusHeader
            searchAndSortBar
            listBody
            statusBar
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isPortfolioMode ? "briefcase.fill" : "chart.bar.fill")
                        .foregroundColor(.accentColor)
                    Text(viewModel.isPortfolioMode ? "Portfolio" : "Watchlist")
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.isRefreshing {
                    ProgressView()
                        .scaleEffect(0.65)
                        .frame(width: 18, height: 18)
                }

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh prices (⌘R)")
                .disabled(viewModel.isInitialLoading || viewModel.isRefreshing)
                .keyboardShortcut("r")

                Button {
                    if viewModel.isPortfolioMode {
                        showAddPosition = true
                    } else {
                        showAddStock = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help(viewModel.isPortfolioMode ? "Add position" : "Add stock to watchlist (⌘N)")
                .keyboardShortcut("n")

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .focusedSceneValue(\.selectedStockSymbol, viewModel.selectedStock?.symbol)
        .onDeleteCommand {
            if let symbol = viewModel.selectedStock?.symbol {
                if viewModel.isPortfolioMode {
                    viewModel.portfolioStore.remove(symbol: symbol)
                } else {
                    viewModel.removeStock(symbol: symbol)
                }
            }
        }
        .sheet(isPresented: $showAddPosition) {
            AddPositionView(viewModel: viewModel)
        }
    }

    // MARK: - Market Status Header

    private var marketStatusHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.marketStatus.icon)
                .font(.system(size: 12))
                .foregroundColor(viewModel.marketStatus.color)

            Text(viewModel.marketStatus.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(viewModel.marketStatus.color)

            Spacer()

            if viewModel.isPortfolioMode && !viewModel.portfolioStore.positions.isEmpty {
                portfolioSummary
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var portfolioSummary: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedPortfolioTotalValue)
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.formattedPortfolioTotalProfitLoss + " (\(viewModel.formattedPortfolioTotalProfitLossPercent))")
                    .font(.system(size: 10))
                    .foregroundColor(viewModel.portfolioTotalProfitLoss >= 0 ?
                        Color(red: 0.18, green: 0.80, blue: 0.44) :
                        Color(red: 0.95, green: 0.27, blue: 0.27))
            }
        }
    }

    // MARK: - Search and Sort Bar

    private var searchAndSortBar: some View {
        HStack(spacing: 8) {
            // Portfolio toggle
            Toggle(isOn: $viewModel.isPortfolioMode) {
                HStack(spacing: 4) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 11))
                    Text("Portfolio")
                        .font(.system(size: 12))
                }
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Search bar
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("Search", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(maxWidth: 180)

            Spacer()

            // Sort options
            Menu {
                ForEach(SortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                    Text(viewModel.sortOption.rawValue)
                        .font(.system(size: 11))
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 100)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Body

    @ViewBuilder
    private var listBody: some View {
        if viewModel.isInitialLoading {
            loadingView
        } else if viewModel.isPortfolioMode {
            portfolioBody
        } else if viewModel.sortedStocks.isEmpty {
            emptyView
        } else {
            stockList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .scaleEffect(1.1)
            Text("Fetching live prices…")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: viewModel.isPortfolioMode ? "briefcase" : "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .opacity(0.3)
            Text(viewModel.isPortfolioMode ? "No positions yet" : "Watchlist is empty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Text(viewModel.isPortfolioMode ? "Add positions to track your portfolio." : "Add stocks to start tracking prices.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(0.6)
            Button(viewModel.isPortfolioMode ? "Add Position" : "Add Stock") {
                if viewModel.isPortfolioMode {
                    showAddPosition = true
                } else {
                    showAddStock = true
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var portfolioBody: some View {
        if viewModel.portfolioStore.positions.isEmpty {
            portfolioEmptyView
        } else {
            portfolioList
        }
    }

    private var portfolioEmptyView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "briefcase")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .opacity(0.3)
            Text("No positions yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Add positions to track your portfolio.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(0.6)
            Button("Add Position") {
                showAddPosition = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var stockList: some View {
        List(viewModel.sortedStocks, id: \.id, selection: $viewModel.selectedStock) { stock in
            StockRowView(stock: stock, animationsEnabled: viewModel.animationsEnabled)
                .tag(stock)
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.removeStock(symbol: stock.symbol)
                    } label: {
                        Label("Remove \"\(stock.symbol)\"", systemImage: "trash")
                    }
                }
        }
        .listStyle(.inset)
    }

    private var portfolioList: some View {
        List(viewModel.sortedStocks, id: \.id, selection: $viewModel.selectedStock) { stock in
            if let position = viewModel.portfolioStore.position(for: stock.symbol) {
                PortfolioRowView(stock: stock, position: position, animationsEnabled: viewModel.animationsEnabled)
                    .tag(stock)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.portfolioStore.remove(symbol: stock.symbol)
                        } label: {
                            Label("Remove \"\(stock.symbol)\"", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        if let err = viewModel.error {
            errorStatusBar(error: err)
        } else {
            normalStatusBar
        }
    }

    private func errorStatusBar(error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if viewModel.retryCountdown > 0 {
                    Text("Retrying in \(viewModel.retryCountdown)s...")
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.7))
                }
            }

            Spacer()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                    Text("Retry")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(viewModel.isRefreshing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.orange.opacity(0.5))
                .frame(height: 2)
        }
    }

    private var normalStatusBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text("Updated \(viewModel.formattedLastUpdated)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            // Gainer / loser summary
            if !viewModel.stocks.isEmpty && viewModel.lastUpdated != nil {
                HStack(spacing: 6) {
                    if viewModel.gainers > 0 {
                        Text("▲\(viewModel.gainers)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.44))
                    }
                    if viewModel.losers > 0 {
                        Text("▼\(viewModel.losers)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.27, blue: 0.27))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Portfolio Row View

struct PortfolioRowView: View {
    let stock: Stock
    let position: PortfolioPosition
    let animationsEnabled: Bool
    @State private var flashGreen = false
    @State private var flashRed = false

    var body: some View {
        HStack(spacing: 10) {
            // Symbol + name + shares
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(Int(position.shares)) shares @ \(position.formattedCostPerShare)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, alignment: .leading)

            Spacer()

            // Current value
            VStack(alignment: .trailing, spacing: 3) {
                Text(stock.price > 0 ? position.formattedCurrentValue(price: stock.price) : "—")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(
                        flashGreen ? Color(red: 0.18, green: 0.80, blue: 0.44)
                        : flashRed ? Color(red: 0.95, green: 0.27, blue: 0.27)
                        : .primary
                    )
                    .animation(animationsEnabled ? .easeInOut(duration: 0.3) : .default, value: flashGreen || flashRed)

                if stock.price > 0 {
                    Text(position.formattedProfitLossPercent(price: stock.price))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(position.profitLoss(price: stock.price) >= 0 ?
                            Color(red: 0.18, green: 0.80, blue: 0.44) :
                            Color(red: 0.95, green: 0.27, blue: 0.27))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(position.profitLoss(price: stock.price) >= 0 ?
                                    Color(red: 0.18, green: 0.80, blue: 0.44).opacity(0.15) :
                                    Color(red: 0.95, green: 0.27, blue: 0.27).opacity(0.15))
                        )
                } else {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
        .onChange(of: stock.price) { old, new in
            guard animationsEnabled else { return }
            guard old > 0, new > 0, old != new else { return }
            if new > old {
                flashGreen = true
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    flashGreen = false
                }
            } else {
                flashRed = true
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    flashRed = false
                }
            }
        }
    }
}

// MARK: - Add Position View

struct AddPositionView: View {
    @ObservedObject var viewModel: StockListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var shares = ""
    @State private var costPerShare = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Position")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                TextField("Symbol (e.g., AAPL)", text: $symbol)
                    .textFieldStyle(.roundedBorder)

                TextField("Shares", text: $shares)
                    .textFieldStyle(.roundedBorder)

                TextField("Cost per Share", text: $costPerShare)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            .frame(width: 280)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    addPosition()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 340, height: 280)
    }

    private var isValid: Bool {
        !symbol.isEmpty &&
        Double(shares) != nil &&
        Double(costPerShare) != nil
    }

    private func addPosition() {
        guard let sharesValue = Double(shares),
              let costValue = Double(costPerShare),
              sharesValue > 0,
              costValue > 0 else {
            errorMessage = "Please enter valid numbers"
            return
        }

        let upperSymbol = symbol.uppercased().trimmingCharacters(in: .whitespaces)

        // Get the stock name if available
        let stockName = viewModel.stocks.first(where: { $0.symbol == upperSymbol })?.name ?? upperSymbol

        viewModel.portfolioStore.add(symbol: upperSymbol, shares: sharesValue, costPerShare: costValue, name: stockName)

        // If not in watchlist, add it
        if !viewModel.stocks.contains(where: { $0.symbol == upperSymbol }) {
            Task {
                _ = await viewModel.addStock(symbol: upperSymbol)
            }
        }

        dismiss()
    }
}
