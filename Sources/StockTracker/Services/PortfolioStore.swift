import Foundation
import Combine

@MainActor
final class PortfolioStore: ObservableObject {
    static let shared = PortfolioStore()

    @Published private(set) var positions: [PortfolioPosition] = []

    private let key = "portfolio_positions_v1"

    private init() { load() }

    func add(symbol: String, shares: Double, costPerShare: Double, name: String = "") {
        let upper = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        guard !upper.isEmpty else { return }

        if let existingIndex = positions.firstIndex(where: { $0.symbol == upper }) {
            // Update existing position - recalculate average cost
            let existing = positions[existingIndex]
            let totalShares = existing.shares + shares
            let totalCost = (existing.shares * existing.costPerShare) + (shares * costPerShare)
            let newAvgCost = totalCost / totalShares

            positions[existingIndex] = PortfolioPosition(
                symbol: upper,
                shares: totalShares,
                costPerShare: newAvgCost,
                name: name.isEmpty ? existing.name : name
            )
        } else {
            positions.append(PortfolioPosition(
                symbol: upper,
                shares: shares,
                costPerShare: costPerShare,
                name: name
            ))
        }
        save()
    }

    func update(symbol: String, shares: Double, costPerShare: Double) {
        let upper = symbol.uppercased()
        guard let index = positions.firstIndex(where: { $0.symbol == upper }) else { return }

        positions[index] = PortfolioPosition(
            symbol: upper,
            shares: shares,
            costPerShare: costPerShare,
            name: positions[index].name
        )
        save()
    }

    func remove(symbol: String) {
        let upper = symbol.uppercased()
        positions.removeAll { $0.symbol == upper }
        save()
    }

    func updateName(for symbol: String, name: String) {
        let upper = symbol.uppercased()
        guard let index = positions.firstIndex(where: { $0.symbol == upper }) else { return }
        positions[index] = PortfolioPosition(
            symbol: upper,
            shares: positions[index].shares,
            costPerShare: positions[index].costPerShare,
            name: name
        )
        save()
    }

    func position(for symbol: String) -> PortfolioPosition? {
        positions.first { $0.symbol == symbol.uppercased() }
    }

    var totalValue: Double {
        0 // Calculated with current prices in ViewModel
    }

    private func save() {
        if let data = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([PortfolioPosition].self, from: data) {
            positions = saved
        }
    }
}
