import SwiftUI

struct StockRowView: View {
    let stock: Stock
    @State private var flashGreen = false
    @State private var flashRed = false

    var body: some View {
        HStack(spacing: 10) {
            // Symbol + name
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.symbol)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(stock.name)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 96, alignment: .leading)

            // Sparkline
            Group {
                if !stock.sparklineData.isEmpty {
                    SparklineView(data: stock.sparklineData, isPositive: stock.isPositive)
                } else {
                    Rectangle().fill(Color.clear)
                }
            }
            .frame(width: 60, height: 30)

            Spacer()

            // Market state indicator
            if stock.price > 0 {
                marketStateBadge
            }

            // Price + change
            VStack(alignment: .trailing, spacing: 3) {
                Text(stock.price > 0 ? stock.formattedPrice : "—")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(
                        flashGreen ? Color(red: 0.18, green: 0.80, blue: 0.44)
                        : flashRed ? Color(red: 0.95, green: 0.27, blue: 0.27)
                        : .primary
                    )
                    .animation(.easeInOut(duration: 0.3), value: flashGreen || flashRed)

                if stock.price > 0 {
                    Text(stock.formattedChangePercent)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(stock.isPositive ? Color(red: 0.18, green: 0.80, blue: 0.44) : Color(red: 0.95, green: 0.27, blue: 0.27))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stock.isPositive
                                    ? Color(red: 0.18, green: 0.80, blue: 0.44).opacity(0.15)
                                    : Color(red: 0.95, green: 0.27, blue: 0.27).opacity(0.15))
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

    @ViewBuilder
    private var marketStateBadge: some View {
        switch stock.marketState {
        case .regular:
            EmptyView()
        case .preMarket, .prepre:
            Text("PRE")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.orange)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.orange.opacity(0.12)))
        case .postMarket, .postpost:
            Text("AH")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.purple)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.purple.opacity(0.12)))
        case .closed:
            Text("CLOSED")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.12)))
        }
    }
}
