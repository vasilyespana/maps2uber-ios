import SwiftUI
import MapKit

struct ResultsView: View {
    let destination: Destination
    let mapURL: String
    @ObservedObject var settings: ProviderSettings
    let pickup: RideLatLng?

    @State private var camera: MapCameraPosition

    private let probes: [Probe]

    init(destination: Destination, mapURL: String, settings: ProviderSettings, pickup: RideLatLng?) {
        self.destination = destination
        self.mapURL = mapURL
        self.settings = settings
        self.pickup = pickup
        self.probes = (0..<10).map { i in
            let (la, lo) = GeoMath.destPoint(lat: destination.lat, lng: destination.lng,
                                             bearingDeg: Double(i * 36), distM: 100)
            return Probe(index: i + 1, bearing: i * 36, lat: la, lng: lo)
        }
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: destination.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))))
    }

    var body: some View {
        List {
            Section {
                Map(position: $camera) {
                    // Map pins keep a single click-through to the PRIMARY
                    // provider — no price-comparison link here (Vasily's
                    // spec: comparison links live in the table rows only).
                    Annotation(destination.name, coordinate: destination.coordinate) {
                        Button {
                            open(provider: settings.primary, destLat: destination.lat,
                                 destLng: destination.lng, name: destination.name,
                                 type: "main", bearing: nil)
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title).foregroundStyle(.green)
                        }
                    }
                    ForEach(probes) { p in
                        Annotation("Point \(p.index)", coordinate: p.coordinate) {
                            Button {
                                open(provider: settings.primary, destLat: p.lat, destLng: p.lng,
                                     name: "Point \(p.index)", type: "probe", bearing: p.bearing)
                            } label: {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2).foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if destination.geocoded {
                    Text("Approximate pin — found by address search, please check it on the map.")
                        .font(.caption).foregroundStyle(.orange)
                }

                Button {
                    open(provider: settings.primary, destLat: destination.lat, destLng: destination.lng,
                         name: destination.name, type: "main", bearing: nil)
                } label: {
                    Label("Open in \(settings.primary.name) 🚕", systemImage: "car.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } header: {
                VStack(alignment: .leading) {
                    Text(destination.name).font(.headline)
                    Text("\(destination.address)")
                    Text(String(format: "%.6f, %.6f", destination.lat, destination.lng))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("10 price probes (100 m circle)") {
                ForEach(probes) { p in
                    // Every table row carries TWO links: the primary
                    // provider and the second (comparison) provider.
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Point \(p.index)")
                            Text(String(format: "%.6f, %.6f", p.lat, p.lng))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(settings.primary.name) {
                            open(provider: settings.primary, destLat: p.lat, destLng: p.lng,
                                 name: "Point \(p.index)", type: "probe", bearing: p.bearing)
                        }
                        .buttonStyle(.bordered)
                        Button(settings.second.name) {
                            open(provider: settings.second, destLat: p.lat, destLng: p.lng,
                                 name: "Point \(p.index)", type: "probe", bearing: p.bearing)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("Ride links")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Launch flow (mirrors Android's RideProviderLauncher): native deep
    /// link when the provider app answers its scheme; otherwise the
    /// provider's universal web URL; otherwise the App Store page so the
    /// user can install it. (Android: installed-app intent → web → store.)
    private func open(provider: RideProvider, destLat: Double, destLng: Double,
                      name: String, type: String, bearing: Int?) {
        let dest = RideLatLng(lat: destLat, lng: destLng)
        let deep = provider.buildDeepLink(pickup, dest, name)
        let universal = provider.buildUniversalUrl(dest)

        var target: String?
        if let deep, let scheme = provider.scheme,
           let probeURL = URL(string: "\(scheme)://"),
           UIApplication.shared.canOpenURL(probeURL) {
            target = deep
        } else if let universal {
            target = universal
        } else if let deep {
            target = deep // scheme could not be probed; try the link anyway
        } else {
            target = provider.appStoreURL
        }

        guard let target, let url = URL(string: target) else { return }
        NetworkService.shared.reportClick(deepLink: target, mapURL: mapURL,
                                          linkType: type, bearing: bearing)
        UIApplication.shared.open(url)
    }
}
