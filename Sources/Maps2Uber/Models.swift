import Foundation
import CoreLocation

// MARK: - API models (mirror the Cloudflare worker)

struct ResolveResponse: Codable {
    let ok: Bool
    let lat: Double?
    let lng: Double?
    let name: String?
    let address: String?
    let geocoded: Bool?
    let error: String?
}

struct FailureReport: Codable {
    let url: String
    let error: String
    let source: String = "ios"
}

struct SuccessReport: Codable {
    let url: String
    let source: String = "ios"
}

struct ClickReport: Codable {
    let deep_link: String
    let map_url: String
    let link_type: String
    let probe_bearing: Int?
    let source: String = "ios"
}

/// Click-event payload for POST /api/click-events (worker contract,
/// mirrors Android). Vasily directive 2026-10-12: track ALL clicks —
/// which provider people choose (circle vs table, Uber vs Lyft),
/// primary vs the second-provider comparison link, copy/share.
/// No user identity, no device id: the payload has no field for them.
struct ClickEventReport: Codable {
    let event: String
    let provider: String?
    let surface: String
    let position: String?
    let url: String?
    let platform: String = "ios"
    let app_version: String?
    let button_id: String?
    let source: String = "ios"
}

/// Event names + surfaces (server contract: maps2uber worker).
enum ClickEvents {
    static let providerOpenPrimary = "provider_open_primary"
    static let providerOpenSecond = "provider_open_second"
    static let copyLink = "copy_link"
    static let share = "share"
    static let settingsDefaultProviderChange = "settings_default_provider_change"
    static let genericButtonClick = "generic_button_click"

    static let surfaceCircle = "circle"
    static let surfaceTable = "table"
    static let surfaceButton = "button"
    static let surfaceSettings = "settings"

    static let positionPrimary = "primary"
    static let positionSecond = "second"
    static let positionProbe = "probe"
}

// MARK: - App models

struct Destination: Identifiable {
    let id = UUID()
    let lat: Double
    let lng: Double
    let name: String
    let address: String
    let geocoded: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct Probe: Identifiable {
    let id = UUID()
    let index: Int          // 1...10
    let bearing: Int        // 0, 36, ... 324
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

// MARK: - Link building
//
// Provider deep links live in RideProviders.swift (the multi-provider
// catalog mirroring Android). Probe-circle math is GeoMath.destPoint.
// The pre-revival UberLinks builder that lived here was Uber-only and
// sent pickup coordinates 0,0 when the location was unknown; the
// catalog builders omit the pickup point instead.
