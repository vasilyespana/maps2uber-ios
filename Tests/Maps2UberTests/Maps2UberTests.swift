import XCTest
@testable import Maps2Uber

final class Maps2UberTests: XCTestCase {

    private func freshSettings() -> ProviderSettings {
        let suite = "maps2uber-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return ProviderSettings(defaults: defaults)
    }

    // MARK: - Provider catalog

    func testCatalogHasSevenSelectableProvidersInAndroidOrder() {
        XCTAssertEqual(RideProviders.selectable.map(\.id),
                       ["uber", "lyft", "bolt", "freenow", "grab", "gett", "didi"])
        XCTAssertEqual(RideProviders.unsupportedList.map(\.id),
                       ["waymo", "zoox", "apollo-go"])
        XCTAssertEqual(RideProviders.default.id, "uber")
    }

    // MARK: - Second-provider invariants (rework brief acceptance tests)

    func testDefaultSecondProviderIsLyftWhenPrimaryIsUber() {
        let s = freshSettings()
        XCTAssertEqual(s.primaryId, "uber")
        XCTAssertEqual(s.secondId, "lyft")
    }

    func testSettingSecondEqualToPrimaryIsShiftedNotStored() {
        let s = freshSettings()
        s.setSecond("uber") // == primary: must not collide
        XCTAssertEqual(s.secondId, "lyft")
        XCTAssertNotEqual(s.secondId, s.primaryId)
    }

    func testChangingPrimaryOntoSecondRehomesSecond() {
        let s = freshSettings()
        XCTAssertEqual(s.secondId, "lyft")
        s.setPrimary("lyft")
        XCTAssertEqual(s.primaryId, "lyft")
        XCTAssertEqual(s.secondId, "uber") // auto-shifted, still != primary
    }

    func testSecondCanBeAnyProviderExceptPrimary() {
        let s = freshSettings()
        s.setSecond("bolt")
        XCTAssertEqual(s.secondId, "bolt")
        s.setPrimary("grab")
        XCTAssertEqual(s.secondId, "bolt") // untouched: no collision
        XCTAssertTrue(s.secondCandidates.allSatisfy { $0.id != "grab" })
        XCTAssertEqual(s.secondCandidates.count, RideProviders.selectable.count - 1)
    }

    func testUnknownProviderIdsAreIgnored() {
        let s = freshSettings()
        s.setPrimary("waymo") // not selectable (no deep linking)
        XCTAssertEqual(s.primaryId, "uber")
        s.setSecond("nope")
        XCTAssertEqual(s.secondId, "lyft")
    }

    // MARK: - Deep link builders (templates mirror Android)

    private let dest = RideLatLng(lat: 18.4587, lng: -66.1066)

    func testUberDeepLinkOmitsPickupWhenOriginUnknown() {
        let link = RideProviders.byId("uber")!.buildDeepLink(nil, dest, "Condado")!
        XCTAssertTrue(link.hasPrefix("uber://?action=setPickup"))
        XCTAssertFalse(link.contains("pickup["), "pickup must be omitted, never 0,0: \(link)")
        XCTAssertTrue(link.contains("dropoff[latitude]=18.4587"))
        XCTAssertTrue(link.contains("dropoff[nickname]=Condado"))
    }

    func testUberDeepLinkIncludesPickupWhenOriginKnown() {
        let origin = RideLatLng(lat: 18.45, lng: -66.1)
        let link = RideProviders.byId("uber")!.buildDeepLink(origin, dest, "Condado")!
        XCTAssertTrue(link.contains("pickup[latitude]=18.45"))
        XCTAssertTrue(link.contains("pickup[longitude]=-66.1"))
    }

    func testLyftLinksMatchAndroidTemplates() {
        let lyft = RideProviders.byId("lyft")!
        XCTAssertEqual(lyft.buildDeepLink(nil, dest, "X"),
                       "lyft://ridetype?id=lyft&destination[latitude]=18.4587&destination[longitude]=-66.1066")
        XCTAssertEqual(lyft.buildUniversalUrl(dest),
                       "https://lyft.com/ride?id=lyft&destination[latitude]=18.4587&destination[longitude]=-66.1066")
    }

    func testBoltFreeNowGrabGettDeepLinks() {
        XCTAssertEqual(RideProviders.byId("bolt")!.buildDeepLink(nil, dest, "X"),
                       "bolt://ride?destination_lat=18.4587&destination_lng=-66.1066")
        XCTAssertEqual(RideProviders.byId("freenow")!.buildDeepLink(nil, dest, "X"),
                       "freenow://ride?destination_latitude=18.4587&destination_longitude=-66.1066")
        XCTAssertEqual(RideProviders.byId("grab")!.buildDeepLink(nil, dest, "X"),
                       "grab://open?screenType=BOOKING&dropoff[latitude]=18.4587&dropoff[longitude]=-66.1066")
        XCTAssertEqual(RideProviders.byId("gett")!.buildDeepLink(nil, dest, "X"), "gett://")
    }

    func testDiDiHasNoDeepLinkButHasAppStoreFallback() {
        let didi = RideProviders.byId("didi")!
        XCTAssertNil(didi.buildDeepLink(nil, dest, "X"))
        XCTAssertNil(didi.buildUniversalUrl(dest))
        XCTAssertEqual(didi.appStoreURL, "https://apps.apple.com/app/id1362398401")
    }

    // MARK: - Formatting + probe math

    func testCoordFormattingHasNoTrailingZeros() {
        XCTAssertEqual(LinkFormat.coord(18.4587), "18.4587")
        XCTAssertEqual(LinkFormat.coord(-66.0), "-66")
        XCTAssertEqual(LinkFormat.coord(0), "0")
    }

    func testEncodeUriComponentUsesJavaScriptSemantics() {
        XCTAssertEqual(LinkFormat.encodeUriComponent("A b&Café"), "A%20b%26Caf%C3%A9")
        XCTAssertEqual(LinkFormat.encodeUriComponent("it's (ok)!"), "it's%20(ok)!")
    }

    func testDestPointLandsRoughly100MetersAway() {
        let (lat, lng) = GeoMath.destPoint(lat: 18.4587, lng: -66.1066, bearingDeg: 90, distM: 100)
        // Haversine back to the origin.
        let p = Double.pi / 180
        let dLat = (lat - 18.4587) * p, dLng = (lng + 66.1066) * p
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(18.4587 * p) * cos(lat * p) * sin(dLng / 2) * sin(dLng / 2)
        let meters = 6371000.0 * 2 * atan2(sqrt(a), sqrt(1 - a))
        XCTAssertEqual(meters, 100, accuracy: 1.0)
    }

    // MARK: - Click-event telemetry (worker contract)

    func testClickEventReportEncodesWorkerContractKeys() throws {
        let report = ClickEventReport(
            event: ClickEvents.providerOpenSecond, provider: "lyft",
            surface: ClickEvents.surfaceTable, position: ClickEvents.positionSecond,
            url: "https://maps.app.goo.gl/xyz", app_version: "1.5.0", button_id: nil)
        let data = try JSONEncoder().encode(report)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["event"] as? String, "provider_open_second")
        XCTAssertEqual(json["provider"] as? String, "lyft")
        XCTAssertEqual(json["surface"] as? String, "table")
        XCTAssertEqual(json["position"] as? String, "second")
        XCTAssertEqual(json["url"] as? String, "https://maps.app.goo.gl/xyz")
        XCTAssertEqual(json["platform"] as? String, "ios")
        XCTAssertEqual(json["app_version"] as? String, "1.5.0")
        XCTAssertEqual(json["source"] as? String, "ios")
        XCTAssertNil(json["button_id"])
        // No identity fields exist in the payload, by design.
        XCTAssertNil(json["device_id"])
        XCTAssertNil(json["user_id"])
    }
}
