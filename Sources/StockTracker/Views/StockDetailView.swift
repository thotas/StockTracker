import SwiftUI

struct StockDetailView: View {
    let stock: Stock

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if !stock.sparklineData.isEmpty { chartSection }
                statsGrid
                if stock.weekHigh52 > 0, stock.weekLow52 > 0 { rangeSection }
                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(stock.name)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.price > 0 ? "\(stock.currency) \(stock.formattedPrice)" : "—")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                    HStack(spacing: 6) {
                        Text(stock.price > 0 ? stock.formattedChange : "—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(changeColor)
                        Text(stock.price > 0 ? stock.formattedChangePercent : "—")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(changeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(changeColor.opacity(0.15))
                            )
                    }
                }
            }

            // Market status row
            HStack(spacing: 8) {
                Circle()
                    .fill(marketDotColor)
                    .frame(width: 7, height: 7)
                Text(stock.marketState.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if let updated = stock.lastUpdated {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(updated, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today", systemImage: "chart.xyaxis.line")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            SparklineView(data: stock.sparklineData, isPositive: stock.isPositive, lineWidth: 2)
                .frame(height: 110)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Key Statistics")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                statCard("Open",       stock.open > 0 ? String(format: "%.2f", stock.open) : "—")
                statCard("Volume",     stock.volume > 0 ? stock.formattedVolume : "—")
                statCard("Day High",   stock.high > 0 ? String(format: "%.2f", stock.high) : "—")
                statCard("Market Cap", stock.marketCap > 0 ? stock.formattedMarketCap : "—")
                statCard("Day Low",    stock.low > 0 ? String(format: "%.2f", stock.low) : "—")
                statCard("Prev Close", stock.previousClose > 0 ? String(format: "%.2f", stock.previousClose) : "—")
            }
        }
    }

    private func statCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    // MARK: - 52-Week Range

    private var rangeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("52-Week Range")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                GeometryReader { geo in
                    let totalRange = stock.weekHigh52 - stock.weekLow52
                    let progress = totalRange > 0
                        ? min(max((stock.price - stock.weekLow52) / totalRange, 0), 1)
                        : 0.5
                    let fillW = geo.size.width * CGFloat(progress)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(NSColor.separatorColor))
                            .frame(height: 6)

                        // Color by position: near high = green, near low = orange
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progress > 0.5
                                ? Color(red: 0.18, green: 0.80, blue: 0.44)
                                : Color.orange)
                            .frame(width: fillW, height: 6)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 13, height: 13)
                            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                            .offset(x: fillW - 6.5)
                    }
                }
                .frame(height: 13)

                HStack {
                    Text(String(format: "%.2f", stock.weekLow52))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", stock.weekHigh52))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    // MARK: - Helpers

    private var changeColor: Color {
        stock.isPositive
            ? Color(red: 0.18, green: 0.80, blue: 0.44)
            : Color(red: 0.95, green: 0.27, blue: 0.27)
    }

    private var marketDotColor: Color {
        switch stock.marketState {
        case .regular: .green
        case .preMarket, .prepre, .postMarket, .postpost: .orange
        case .closed: .gray
        }
    }
}

// MARK: - Empty Detail

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
                .opacity(0.25)
            Text("Select a stock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Pick any stock from the watchlist\nto see live details and charts.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .opacity(0.6)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
