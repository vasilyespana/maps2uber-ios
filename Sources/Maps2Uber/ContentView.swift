import SwiftUI

struct ContentView: View {
    @State private var mapsURL = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var destination: Destination?
    @State private var submittedURL = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("📍 Maps → Uber")
                    .font(.largeTitle.bold())
                Text("Paste a Google Maps link, get an Uber deep link to that exact spot — plus 10 probes on a 100 m circle to compare prices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("https://maps.app.goo.gl/…", text: $mapsURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { submit() }

                Button {
                    submit()
                } label: {
                    if isLoading { ProgressView() } else { Text("Go").bold() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || mapsURL.trimmingCharacters(in: .whitespaces).isEmpty)

                if let error {
                    Text(error).foregroundStyle(.red).font(.callout)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(item: $destination) { dest in
                ResultsView(destination: dest, mapURL: submittedURL)
            }
            .onAppear {
                // Offer clipboard contents if it looks like a Maps link.
                if mapsURL.isEmpty,
                   let clip = UIPasteboard.general.string,
                   clip.contains("google.com/maps") || clip.contains("goo.gl") {
                    mapsURL = clip
                }
            }
        }
    }

    private func submit() {
        let url = mapsURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        isLoading = true
        error = nil
        Task {
            let result = await NetworkService.shared.resolve(url: url)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let dest):
                    submittedURL = url
                    destination = dest
                case .failure(let msg):
                    error = msg
                }
            }
        }
    }
}

// NavigationStack item support
extension Destination: Hashable {
    static func == (lhs: Destination, rhs: Destination) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
