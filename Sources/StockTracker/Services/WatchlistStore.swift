import Foundation
import Combine
import SwiftUI

struct Watchlist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var symbols: [String]

    init(id: UUID = UUID(), name: String, symbols: [String] = []) {
        self.id = id
        self.name = name
        self.symbols = symbols
    }
}

@MainActor
final class WatchlistStore: ObservableObject {
    static let shared = WatchlistStore()

    @Published private(set) var watchlists: [Watchlist] = []
    @Published var currentWatchlistId: UUID?

    private let watchlistsKey = "watchlists_v1"
    private let currentIdKey = "current_watchlist_id_v1"
    private let defaults: [Watchlist] = [
        Watchlist(name: "My Watchlist", symbols: ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"])
    ]

    var currentWatchlist: Watchlist? {
        guard let id = currentWatchlistId else {
            return watchlists.first
        }
        return watchlists.first { $0.id == id }
    }

    var symbols: [String] {
        currentWatchlist?.symbols ?? []
    }

    private init() { load() }

    // MARK: - CRUD Operations

    func createWatchlist(name: String) {
        let watchlist = Watchlist(name: name)
        watchlists.append(watchlist)
        if currentWatchlistId == nil {
            currentWatchlistId = watchlist.id
        }
        save()
    }

    func deleteWatchlist(id: UUID) {
        watchlists.removeAll { $0.id == id }
        if currentWatchlistId == id {
            currentWatchlistId = watchlists.first?.id
        }
        save()
    }

    func renameWatchlist(id: UUID, name: String) {
        if let index = watchlists.firstIndex(where: { $0.id == id }) {
            watchlists[index].name = name
            save()
        }
    }

    func selectWatchlist(id: UUID) {
        currentWatchlistId = id
        save()
    }

    // MARK: - Symbol Operations (on current watchlist)

    func add(symbol: String) {
        guard let index = watchlists.firstIndex(where: { $0.id == currentWatchlistId }) else { return }
        let s = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !watchlists[index].symbols.contains(s) else { return }
        watchlists[index].symbols.append(s)
        save()
    }

    func remove(symbol: String) {
        guard let index = watchlists.firstIndex(where: { $0.id == currentWatchlistId }) else { return }
        watchlists[index].symbols.removeAll { $0 == symbol.uppercased() }
        save()
    }

    func remove(at offsets: IndexSet) {
        guard let index = watchlists.firstIndex(where: { $0.id == currentWatchlistId }) else { return }
        watchlists[index].symbols.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        guard let index = watchlists.firstIndex(where: { $0.id == currentWatchlistId }) else { return }
        watchlists[index].symbols.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(watchlists) {
            UserDefaults.standard.set(encoded, forKey: watchlistsKey)
        }
        UserDefaults.standard.set(currentWatchlistId?.uuidString, forKey: currentIdKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: watchlistsKey),
           let decoded = try? JSONDecoder().decode([Watchlist].self, from: data) {
            watchlists = decoded
        } else {
            watchlists = defaults
            save()
        }

        if let idString = UserDefaults.standard.string(forKey: currentIdKey),
           let id = UUID(uuidString: idString) {
            currentWatchlistId = id
        } else {
            currentWatchlistId = watchlists.first?.id
        }
    }
}
