import SwiftUI

@main
struct StockTrackerApp: App {
    @State private var showSettings = false
    @State private var showAddStock = false

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings, showAddStock: $showAddStock)
                .frame(minWidth: 720, minHeight: 480)
                .focusedSceneValue(\.addStockTrigger, showAddStock)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1050, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Stock...") {
                    showAddStock = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshStocks, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Remove Selected Stock") {
                    NotificationCenter.default.post(name: .removeSelectedStock, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }

            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Focused Scene Values

struct AddStockTriggerKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var addStockTrigger: Bool? {
        get { self[AddStockTriggerKey.self] }
        set { self[AddStockTriggerKey.self] = newValue }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshStocks = Notification.Name("refreshStocks")
    static let removeSelectedStock = Notification.Name("removeSelectedStock")
}
