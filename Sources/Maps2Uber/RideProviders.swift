import Foundation

/// Simple lat/lng pair used for ride-provider deep link building.
/// Mirrors `RideLatLng` in the Android app's RideProviders.kt.
struct RideLatLng: Equatable {
    let lat: Double
    let lng: Double
}

/// A ride-hailing provider. Mirrors the Android `RideProvider` catalog
/// (vasilyespana/maps2uber-android, core/rides/RideProviders.kt) — same ids,
/// same URI templates, same App Store IDs — so iOS and Android open the
/// same links for the same destination.
struct RideProvider: Identifiable {
    let id: String
    let name: String
    let region: String
    /// App Store numeric ID, used for the install fallback. Nil when unknown.
    let appStoreId: String?
    /// False for providers without destination deep linking —
    /// rendered grayed-out in Settings.
    let deepLinkSupported: Bool
    /// Custom URL scheme used to probe whether the provider app is
    /// installed (`canOpenURL`). Must also be declared under
    /// LSApplicationQueriesSchemes in the Info.plist. Nil when no
    /// verified scheme exists (DiDi).
    let scheme: String?
    /// Builds the native deep-link URI, or nil when the provider has no
    /// verified destination deep link.
    let buildDeepLink: (_ origin: RideLatLng?, _ dest: RideLatLng, _ destName: String) -> String?
    /// Builds the universal web fallback URL, or nil when the provider
    /// publishes none.
    let buildUniversalUrl: (_ dest: RideLatLng) -> String?

    /// App Store product page, the final fallback when the provider app
    /// is not installed and no universal URL exists.
    var appStoreURL: String? {
        appStoreId.map { "https://apps.apple.com/app/id\($0)" }
    }
}

/// The ride provider catalog, in display order (same order as Android).
enum RideProviders {
    static let defaultId = "uber"
    static let defaultSecondId = "lyft"

    static let all: [RideProvider] = [uber, lyft, bolt, freeNow, grab, gett, didi,
                                      unsupported("waymo", "Waymo", "US"),
                                      unsupported("zoox", "Zoox Autonomous", "US"),
                                      unsupported("apollo-go", "Baidu Apollo Go", "China")]

    /// Selectable providers (deep link supported), in display order.
    static var selectable: [RideProvider] { all.filter { $0.deepLinkSupported } }

    /// Grayed-out providers (deep linking not supported), in display order.
    static var unsupportedList: [RideProvider] { all.filter { !$0.deepLinkSupported } }

    static func byId(_ id: String) -> RideProvider? { all.first { $0.id == id } }

    static var `default`: RideProvider { byId(defaultId)! }

    /// The default second (price-comparison) provider for a given primary:
    /// Lyft, unless Lyft itself is the primary — then Uber.
    static func defaultSecond(forPrimary primaryId: String) -> String {
        primaryId == defaultSecondId ? defaultId : defaultSecondId
    }

    // MARK: - Catalog entries (URI templates mirror Android byte-for-byte)

    private static let uber = RideProvider(
        id: "uber", name: "Uber", region: "Global",
        appStoreId: "368677349", deepLinkSupported: true, scheme: "uber",
        buildDeepLink: { origin, dest, destName in
            var s = "uber://?action=setPickup"
            if let origin {
                s += "&pickup[latitude]=\(LinkFormat.coord(origin.lat))"
                s += "&pickup[longitude]=\(LinkFormat.coord(origin.lng))"
            }
            s += "&dropoff[latitude]=\(LinkFormat.coord(dest.lat))"
            s += "&dropoff[longitude]=\(LinkFormat.coord(dest.lng))"
            s += "&dropoff[nickname]=\(LinkFormat.encodeUriComponent(destName))"
            return s
        },
        buildUniversalUrl: { dest in
            // Worker/Android uberLink format: dropoff coordinates only here;
            // the name/address ride along in the deep link when the app is
            // installed. (The pre-revival iOS build also put nickname and
            // formatted_address here; dropped for cross-platform parity.)
            "https://m.uber.com/ul/?action=setPickup"
                + "&dropoff[latitude]=\(LinkFormat.coord(dest.lat))"
                + "&dropoff[longitude]=\(LinkFormat.coord(dest.lng))"
        })

    private static let lyft = RideProvider(
        id: "lyft", name: "Lyft", region: "US & Canada",
        appStoreId: "529379082", deepLinkSupported: true, scheme: "lyft",
        buildDeepLink: { _, dest, _ in
            "lyft://ridetype?id=lyft"
                + "&destination[latitude]=\(LinkFormat.coord(dest.lat))"
                + "&destination[longitude]=\(LinkFormat.coord(dest.lng))"
        },
        buildUniversalUrl: { dest in
            "https://lyft.com/ride?id=lyft"
                + "&destination[latitude]=\(LinkFormat.coord(dest.lat))"
                + "&destination[longitude]=\(LinkFormat.coord(dest.lng))"
        })

    private static let bolt = RideProvider(
        id: "bolt", name: "Bolt", region: "Europe & Africa",
        appStoreId: "675033630", deepLinkSupported: true, scheme: "bolt",
        buildDeepLink: { _, dest, _ in
            "bolt://ride"
                + "?destination_lat=\(LinkFormat.coord(dest.lat))"
                + "&destination_lng=\(LinkFormat.coord(dest.lng))"
        },
        buildUniversalUrl: { _ in nil })

    private static let freeNow = RideProvider(
        id: "freenow", name: "FreeNow", region: "Europe",
        appStoreId: "357852748", deepLinkSupported: true, scheme: "freenow",
        buildDeepLink: { _, dest, _ in
            "freenow://ride"
                + "?destination_latitude=\(LinkFormat.coord(dest.lat))"
                + "&destination_longitude=\(LinkFormat.coord(dest.lng))"
        },
        buildUniversalUrl: { _ in nil })

    private static let grab = RideProvider(
        id: "grab", name: "Grab", region: "Southeast Asia",
        appStoreId: "647268330", deepLinkSupported: true, scheme: "grab",
        buildDeepLink: { _, dest, _ in
            "grab://open?screenType=BOOKING"
                + "&dropoff[latitude]=\(LinkFormat.coord(dest.lat))"
                + "&dropoff[longitude]=\(LinkFormat.coord(dest.lng))"
        },
        buildUniversalUrl: { _ in nil })

    private static let gett = RideProvider(
        id: "gett", name: "Gett", region: "UK / Israel",
        appStoreId: "449655162", deepLinkSupported: true, scheme: "gett",
        buildDeepLink: { _, _, _ in
            // Verified scheme; destination params are not publicly
            // documented, so this opens the Gett app (same as Android).
            "gett://"
        },
        buildUniversalUrl: { _ in nil })

    private static let didi = RideProvider(
        id: "didi", name: "DiDi", region: "Global / LATAM",
        appStoreId: "1362398401", deepLinkSupported: true, scheme: nil,
        // No verifiable destination deep link (same finding as Android):
        // the launcher falls back to the App Store page.
        buildDeepLink: { _, _, _ in nil },
        buildUniversalUrl: { _ in nil })

    private static func unsupported(_ id: String, _ name: String, _ region: String) -> RideProvider {
        RideProvider(id: id, name: name, region: region,
                     appStoreId: nil, deepLinkSupported: false, scheme: nil,
                     buildDeepLink: { _, _, _ in nil },
                     buildUniversalUrl: { _ in nil })
    }
}

/// Number/percent formatting with JavaScript semantics, mirroring the
/// worker and the Android `UberLinks` helpers.
enum LinkFormat {
    /// Like JavaScript Number.toString for typical coordinate magnitudes:
    /// no trailing zeros, no exponent for coordinate-range values.
    static func coord(_ d: Double) -> String {
        if d == 0 { return "0" }
        var s = String(format: "%.10f", d)
        while s.contains("."), s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }

    /// JavaScript encodeURIComponent semantics (UTF-8).
    static func encodeUriComponent(_ s: String) -> String {
        let unreserved = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()".utf8)
        var out = ""
        for byte in s.utf8 {
            if unreserved.contains(byte) {
                out += String(UnicodeScalar(byte))
            } else {
                out += String(format: "%%%02X", byte)
            }
        }
        return out
    }
}

/// Great-circle destination math (same formula as the worker's destPoint).
enum GeoMath {
    /// Destination point distM meters from (lat,lng) on bearingDeg.
    static func destPoint(lat: Double, lng: Double, bearingDeg: Double, distM: Double) -> (Double, Double) {
        let R = 6371000.0
        let br = bearingDeg * .pi / 180
        let la1 = lat * .pi / 180, lo1 = lng * .pi / 180
        let la2 = asin(sin(la1) * cos(distM / R) + cos(la1) * sin(distM / R) * cos(br))
        let lo2 = lo1 + atan2(sin(br) * sin(distM / R) * cos(la1),
                              cos(distM / R) - sin(la1) * sin(la2))
        return (la2 * 180 / .pi, lo2 * 180 / .pi)
    }
}
