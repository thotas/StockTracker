import SwiftUI

struct StockListView: View {
    @ObservedObject var viewModel: StockListViewModel
    @Binding var showAddStock: Bool

    var body: some View {
        VStack(spacing: 0) {
            listBody
            statusBar
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                    Text("Watchlist")
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
                    showAddStock = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add stock to watchlist")
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var listBody: some View {
        if viewModel.isInitialLoading {
            loadingView
        } else if viewModel.stocks.isEmpty {
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
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .opacity(0.3)
            Text("Watchlist is empty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Add stocks to start tracking prices.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(0.6)
            Button("Add Stock") { showAddStock = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var stockList: some View {
        List(viewModel.stocks, id: \.id, selection: $viewModel.selectedStock) { stock in
            StockRowView(stock: stock)
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

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 6) {
            if let err = viewModel.error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text(err)
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("Updated \(viewModel.formattedLastUpdated)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

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
