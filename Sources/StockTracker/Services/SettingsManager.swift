import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - Keys
    private enum Keys {
        static let refreshInterval = "settings_refresh_interval"
        static let animationsEnabled = "settings_animations_enabled"
        static let defaultWatchlist = "settings_default_watchlist"
    }

    // MARK: - Settings

    /// Refresh interval in seconds (5-60 seconds)
    @Published var refreshInterval: Double {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: Keys.refreshInterval)
        }
    }

    /// Enable/disable price flash animations
    @Published var animationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(animationsEnabled, forKey: Keys.animationsEnabled)
        }
    }

    /// Default watchlist symbols (comma-separated)
    @Published var defaultWatchlist: String {
        didSet {
            UserDefaults.standard.set(defaultWatchlist, forKey: Keys.defaultWatchlist)
        }
    }

    /// Computed array of default watchlist symbols
    var defaultWatchlistSymbols: [String] {
        defaultWatchlist
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
            .filter { !$0.isEmpty }
    }

    // MARK: - Initialization

    private init() {
        // Load from UserDefaults with defaults
        let interval = UserDefaults.standard.double(forKey: Keys.refreshInterval)
        self.refreshInterval = interval > 0 ? interval : 15.0

        if UserDefaults.standard.object(forKey: Keys.animationsEnabled) != nil {
            self.animationsEnabled = UserDefaults.standard.bool(forKey: Keys.animationsEnabled)
        } else {
            self.animationsEnabled = true
        }

        let watchlist = UserDefaults.standard.string(forKey: Keys.defaultWatchlist)
        self.defaultWatchlist = watchlist ?? "AAPL,MSFT,GOOGL,AMZN,NVDA"
    }

    // MARK: - Reset

    func resetToDefaults() {
        refreshInterval = 15.0
        animationsEnabled = true
        defaultWatchlist = "AAPL,MSFT,GOOGL,AMZN,NVDA"
    }
}
