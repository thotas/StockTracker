import SwiftUI

struct AddStockView: View {
    @ObservedObject var viewModel: StockListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    private let popular = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "TSLA", "META", "SPY", "BRK-B"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to Watchlist")
                        .font(.system(size: 17, weight: .bold))
                    Text("Enter a ticker symbol like AAPL or TSLA")
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
                // Escape owned by Cancel button; no duplicate binding here
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 16)

            Divider()

            VStack(alignment: .leading, spacing: 20) {
                // Input field
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Symbol", text: $input)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 15, design: .monospaced))
                            .autocorrectionDisabled()
                            .textCase(.uppercase)
                            .onSubmit { Task { await submit() } }
                            .onChange(of: input) { _, _ in
                                errorMessage = nil
                                didSucceed = false
                            }

                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.75)
                                .frame(width: 20)
                        } else if didSucceed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    if let err = errorMessage {
                        Label(err, systemImage: "exclamationmark.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }

                // Popular stocks
                VStack(alignment: .leading, spacing: 8) {
                    Text("Popular")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    let cols = Array(repeating: GridItem(.flexible()), count: 3)
                    LazyVGrid(columns: cols, spacing: 6) {
                        ForEach(popular, id: \.self) { sym in
                            let inWatchlist = viewModel.stocks.contains(where: { $0.symbol == sym })
                            Button(sym) {
                                input = sym
                                Task { await submit() }
                            }
                            .buttonStyle(TickerButtonStyle(dimmed: inWatchlist))
                            .disabled(inWatchlist || isValidating)
                        }
                    }
                }

                Spacer()

                // Action buttons
                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])

                    Spacer()

                    Button("Add Stock") { Task { await submit() } }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return)
                        .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                }
            }
            .padding(24)
        }
        .frame(width: 370, height: 390)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func submit() async {
        let sym = input.uppercased().trimmingCharacters(in: .whitespaces)
        guard !sym.isEmpty else { return }

        isValidating = true
        errorMessage = nil

        let ok = await viewModel.addStock(symbol: sym)

        isValidating = false

        if ok {
            didSucceed = true
            try? await Task.sleep(nanoseconds: 350_000_000)
            dismiss()
        } else {
            if viewModel.stocks.contains(where: { $0.symbol == sym }) {
                errorMessage = "\(sym) is already in your watchlist"
            } else {
                errorMessage = "\"\(sym)\" not found. Check the symbol and try again."
            }
        }
    }
}

// MARK: - Ticker Button Style

struct TickerButtonStyle: ButtonStyle {
    var dimmed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(dimmed ? .secondary : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
            )
            .opacity(configuration.isPressed ? 0.65 : (dimmed ? 0.4 : 1.0))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
