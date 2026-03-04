import Foundation
import Combine
import SwiftUI

@MainActor
final class WatchlistStore: ObservableObject {
    static let shared = WatchlistStore()

    @Published private(set) var symbols: [String] = []

    private let key = "watchlist_symbols_v1"
    private let defaults: [String] = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]

    private init() { load() }

    func add(symbol: String) {
        let s = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !symbols.contains(s) else { return }
        symbols.append(s)
        save()
    }

    func remove(symbol: String) {
        symbols.removeAll { $0 == symbol.uppercased() }
        save()
    }

    func remove(at offsets: IndexSet) {
        symbols.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        symbols.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        UserDefaults.standard.set(symbols, forKey: key)
    }

    private func load() {
        if let saved = UserDefaults.standard.stringArray(forKey: key) {
            symbols = saved
        } else {
            symbols = defaults
            save()
        }
    }
}
