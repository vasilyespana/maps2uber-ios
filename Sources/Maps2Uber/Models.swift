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

// MARK: - Uber deep link builder (mirrors worker's uberLink)

enum UberLinks {
    static func deepLink(pickup: CLLocationCoordinate2D?,
                         destLat: Double, destLng: Double,
                         name: String, address: String) -> String {
        var q = "action=setPickup"
        q += "&pickup[latitude]=\(pickup?.latitude ?? 0)"
        q += "&pickup[longitude]=\(pickup?.longitude ?? 0)"
        q += "&dropoff[latitude]=\(destLat)"
        q += "&dropoff[longitude]=\(destLng)"
        q += "&dropoff[nickname]=\(enc(name))"
        q += "&dropoff[formatted_address]=\(enc(address))"
        return "https://m.uber.com/ul/?" + q
    }

    private static func enc(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

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
