import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StockListViewModel()
    @State private var showAddStock = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            StockListView(viewModel: viewModel, showAddStock: $showAddStock)
                .frame(minWidth: 300, idealWidth: 340)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 440)
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
    }
}
