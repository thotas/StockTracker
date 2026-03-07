import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StockListViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @Binding var showSettings: Bool
    @Binding var showAddStock: Bool

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            StockListView(viewModel: viewModel, showAddStock: $showAddStock, showSettings: $showSettings)
                .frame(minWidth: 300, idealWidth: 340)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 440)
                .onReceive(NotificationCenter.default.publisher(for: .refreshStocks)) { _ in
                    Task { await viewModel.refresh() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .removeSelectedStock)) { _ in
                    if let symbol = viewModel.selectedStock?.symbol {
                        viewModel.removeStock(symbol: symbol)
                    }
                }
        } detail: {
            if let stock = viewModel.selectedStock {
                StockDetailView(stock: stock)
            } else {
                EmptyDetailView()
            }
        }
        .sheet(isPresented: $showAddStock) {
            AddStockView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
