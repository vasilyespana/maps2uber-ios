import SwiftUI

/// Provider selection. The primary provider drives the big "Open in …"
/// button and every map-pin tap. The second provider appears next to it
/// on each row of the results table for price comparison — never on the
/// map pins (Vasily's second-provider spec, rework brief 2026-10-08).
struct SettingsView: View {
    @ObservedObject var settings: ProviderSettings

    var body: some View {
        Form {
            Section {
                ForEach(RideProviders.selectable) { provider in
                    Button {
                        settings.setPrimary(provider.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(provider.name).foregroundStyle(.primary)
                                Text(provider.region).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.primaryId == provider.id {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Ride provider")
            } footer: {
                Text("The main button and the map pins open this provider.")
            }

            Section {
                ForEach(settings.secondCandidates) { provider in
                    Button {
                        settings.setSecond(provider.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(provider.name).foregroundStyle(.primary)
                                Text(provider.region).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.secondId == provider.id {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Second provider (price comparison)")
            } footer: {
                Text("Shown next to \(settings.primary.name) on every row of the results table so you can compare prices. Any provider except the main one; defaults to Lyft.")
            }

            Section("Coming soon") {
                ForEach(RideProviders.unsupportedList) { provider in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(provider.name)
                            Text(provider.region).font(.caption)
                        }
                        Spacer()
                        Text("No deep linking yet").font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Section("Pickup") {
                Text("When location access is allowed, your current location is sent as the pickup point. Otherwise the provider app uses its own pickup detection.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
