import SwiftUI
import MapKit

struct ResultsView: View {
    let destination: Destination
    let mapURL: String

    @State private var camera: MapCameraPosition
    @State private var selectedProbe: Probe?

    private let probes: [Probe]
    private let mainLink: String

    init(destination: Destination, mapURL: String) {
        self.destination = destination
        self.mapURL = mapURL
        self.probes = (0..<10).map { i in
            let (la, lo) = UberLinks.destPoint(lat: destination.lat, lng: destination.lng,
                                               bearingDeg: Double(i * 36), distM: 100)
            return Probe(index: i + 1, bearing: i * 36, lat: la, lng: lo)
        }
        self.mainLink = UberLinks.deepLink(pickup: nil, destLat: destination.lat, destLng: destination.lng,
                                            name: destination.name, address: destination.address)
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: destination.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008))))
    }

    var body: some View {
        List {
            Section {
                Map(position: $camera) {
                    Annotation(destination.name, coordinate: destination.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title).foregroundStyle(.green)
                    }
                    ForEach(probes) { p in
                        Annotation("Point \(p.index)", coordinate: p.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2).foregroundStyle(.blue)
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
                    openUber(link: mainLink, type: "main", bearing: nil)
                } label: {
                    Label("Open in Uber 🚕", systemImage: "car.fill")
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
                    Button {
                        let link = UberLinks.deepLink(pickup: nil, destLat: p.lat, destLng: p.lng,
                                                      name: "Point \(p.index)", address: destination.address)
                        openUber(link: link, type: "probe", bearing: p.bearing)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Point \(p.index)")
                                Text(String(format: "%.6f, %.6f", p.lat, p.lng))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Uber 🚕").font(.callout)
                        }
                    }
                }
            }
        }
        .navigationTitle("Uber links")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openUber(link: String, type: String, bearing: Int?) {
        NetworkService.shared.reportClick(deepLink: link, mapURL: mapURL,
                                           linkType: type, bearing: bearing)
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
