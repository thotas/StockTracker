import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var watchlistInput: String = ""
    @State private var isResetting = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    refreshIntervalSection
                    animationsSection
                    defaultWatchlistSection
                    resetSection
                }
                .padding(24)
            }
        }
        .frame(width: 450, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            watchlistInput = settings.defaultWatchlist
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 17, weight: .bold))
                Text("Configure StockTracker preferences")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Refresh Interval

    private var refreshIntervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Refresh Interval", systemImage: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))

            HStack(spacing: 12) {
                Slider(
                    value: $settings.refreshInterval,
                    in: 5...60,
                    step: 5
                )
                .frame(maxWidth: 200)

                Text("\(Int(settings.refreshInterval))s")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .frame(width: 45, alignment: .trailing)
            }

            Text("Prices will refresh every \(Int(settings.refreshInterval)) seconds")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Animations

    private var animationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Animations", systemImage: "sparkles")
                .font(.system(size: 13, weight: .semibold))

            Toggle(isOn: $settings.animationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable price flash animations")
                        .font(.system(size: 13))
                    Text("Shows green/red flash when prices change")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    // MARK: - Default Watchlist

    private var defaultWatchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Default Watchlist", systemImage: "list.bullet")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                TextField("Comma-separated symbols", text: $watchlistInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .onChange(of: watchlistInput) { _, newValue in
                        settings.defaultWatchlist = newValue
                    }

                Text("Comma-separated list (e.g., AAPL,MSFT,GOOGL)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if !settings.defaultWatchlistSymbols.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(settings.defaultWatchlistSymbols.prefix(5), id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accentColor.opacity(0.15))
                                )
                        }
                        if settings.defaultWatchlistSymbols.count > 5 {
                            Text("+\(settings.defaultWatchlistSymbols.count - 5)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .semibold))

            Button(role: .destructive) {
                isResetting = true
                settings.resetToDefaults()
                watchlistInput = settings.defaultWatchlist
                isResetting = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                }
            }
            .buttonStyle(.bordered)

            Text("Resets all settings to their default values")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}
