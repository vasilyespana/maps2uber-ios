import Foundation

/// Failure type for resolve calls. (The pre-revival code used
/// `Result<Destination, String>`, which never compiled — `String` does
/// not conform to `Error`. That is why the v1.0.0 CI run failed.)
struct ResolveFailure: Error {
    let message: String
}

/// Talks to the Maps2Uber Cloudflare worker. All telemetry is fire-and-forget.
final class NetworkService {
    static let shared = NetworkService()
    private let base = "https://maps2uber.vasilyespana.workers.dev"
    private let session = URLSession.shared

    // MARK: - Resolve

    func resolve(url: String) async -> Result<Destination, ResolveFailure> {
        guard let reqURL = URL(string: "\(base)/api/resolve?url=\(url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url)") else {
            return .failure(ResolveFailure(message: "Bad request."))
        }
        do {
            let (data, _) = try await session.data(from: reqURL)
            let r = try JSONDecoder().decode(ResolveResponse.self, from: data)
            if r.ok, let lat = r.lat, let lng = r.lng {
                let dest = Destination(
                    lat: lat, lng: lng,
                    name: (r.name?.isEmpty == false) ? r.name! : "Dropped pin",
                    address: r.address ?? r.name ?? "",
                    geocoded: r.geocoded ?? false
                )
                reportSuccess(url: url)
                return .success(dest)
            } else {
                let err = r.error ?? "Could not resolve that link."
                reportFailure(url: url, error: err)
                return .failure(ResolveFailure(message: err))
            }
        } catch {
            let msg = "Network error. Try again."
            reportFailure(url: url, error: msg)
            return .failure(ResolveFailure(message: msg))
        }
    }

    // MARK: - Telemetry (fire-and-forget, never throws)

    func reportFailure(url: String, error: String) {
        post(path: "/api/resolve-failures", body: FailureReport(url: url, error: error))
    }

    func reportSuccess(url: String) {
        post(path: "/api/resolve-success", body: SuccessReport(url: url))
    }

    func reportClick(deepLink: String, mapURL: String, linkType: String, bearing: Int?) {
        post(path: "/api/deep-link-clicks",
             body: ClickReport(deep_link: deepLink, map_url: mapURL,
                               link_type: linkType, probe_bearing: bearing))
    }

    private func post<T: Encodable>(path: String, body: T) {
        guard let url = URL(string: base + path) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(body)
        // Fire-and-forget: intentionally ignore result.
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }
}
