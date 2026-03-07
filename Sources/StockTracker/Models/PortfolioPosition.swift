import Foundation

struct PortfolioPosition: Identifiable, Codable, Equatable {
    var id: String { symbol }
    let symbol: String
    var shares: Double
    var costPerShare: Double
    var name: String

    var totalCost: Double { shares * costPerShare }

    func currentValue(price: Double) -> Double { shares * price }
    func profitLoss(price: Double) -> Double { currentValue(price: price) - totalCost }
    func profitLossPercent(price: Double) -> Double {
        guard totalCost > 0 else { return 0 }
        return (profitLoss(price: price) / totalCost) * 100
    }

    var formattedCostPerShare: String {
        String(format: "$%.2f", costPerShare)
    }

    var formattedTotalCost: String {
        String(format: "$%.2f", totalCost)
    }

    func formattedCurrentValue(price: Double) -> String {
        String(format: "$%.2f", currentValue(price: price))
    }

    func formattedProfitLoss(price: Double) -> String {
        let pl = profitLoss(price: price)
        let sign = pl >= 0 ? "+" : ""
        return "\(sign)\(String(format: "$%.2f", pl))"
    }

    func formattedProfitLossPercent(price: Double) -> String {
        let pl = profitLossPercent(price: price)
        let sign = pl >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", pl))%"
    }
}
