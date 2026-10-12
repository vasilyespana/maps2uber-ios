import Foundation
import Combine

/// Primary + second ride-provider selection, persisted in UserDefaults.
///
/// Implements Vasily's second-provider spec (rework brief, 2026-10-08):
/// - A SECOND provider can be selected in Settings. It has a default and
///   can be changed to any provider EXCEPT the primary.
/// - Invariants enforced here (not just in the UI): the stored second
///   provider is never equal to the primary; if the primary later changes
///   onto the stored second, the second auto-shifts to the default
///   non-primary provider rather than colliding.
final class ProviderSettings: ObservableObject {
    private let defaults: UserDefaults

    private enum Keys {
        static let primary = "ride_provider_id"
        static let second = "second_ride_provider_id"
    }

    @Published private(set) var primaryId: String
    @Published private(set) var secondId: String

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedPrimary = defaults.string(forKey: Keys.primary)
        let primary = RideProviders.selectable.contains { $0.id == storedPrimary }
            ? storedPrimary! : RideProviders.defaultId
        self.primaryId = primary
        let storedSecond = defaults.string(forKey: Keys.second)
        if let storedSecond,
           RideProviders.selectable.contains(where: { $0.id == storedSecond }),
           storedSecond != primary {
            self.secondId = storedSecond
        } else {
            self.secondId = RideProviders.defaultSecond(forPrimary: primary)
        }
    }

    var primary: RideProvider { RideProviders.byId(primaryId) ?? RideProviders.default }
    var second: RideProvider {
        RideProviders.byId(secondId) ?? RideProviders.byId(RideProviders.defaultSecond(forPrimary: primaryId))!
    }

    /// Providers offered for the second slot: every selectable provider
    /// except the current primary.
    var secondCandidates: [RideProvider] {
        RideProviders.selectable.filter { $0.id != primaryId }
    }

    func setPrimary(_ id: String) {
        guard RideProviders.selectable.contains(where: { $0.id == id }) else { return }
        let changed = id != primaryId
        primaryId = id
        defaults.set(id, forKey: Keys.primary)
        if changed {
            // Provider-choice telemetry: which provider people make primary.
            NetworkService.shared.reportClickEvent(
                event: ClickEvents.settingsDefaultProviderChange,
                provider: id, surface: ClickEvents.surfaceSettings,
                position: nil, url: nil)
        }
        if secondId == id {
            // Primary moved onto the second provider: re-home the second.
            secondId = RideProviders.defaultSecond(forPrimary: id)
            defaults.set(secondId, forKey: Keys.second)
        }
    }

    func setSecond(_ id: String) {
        guard RideProviders.selectable.contains(where: { $0.id == id }) else { return }
        guard id != primaryId else {
            // Rejected: the second provider can never equal the primary.
            // Shift to the default non-primary instead of colliding.
            secondId = RideProviders.defaultSecond(forPrimary: primaryId)
            defaults.set(secondId, forKey: Keys.second)
            return
        }
        secondId = id
        defaults.set(id, forKey: Keys.second)
    }
}
