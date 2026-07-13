import Foundation

struct ServerSettings {
    static func normalizedServerURL(from rawValue: String) -> URL? {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if !value.lowercased().hasPrefix("http://") && !value.lowercased().hasPrefix("https://") {
            value = "https://\(value)"
        }

        while value.hasSuffix("/") {
            value.removeLast()
        }

        guard let url = URL(string: value), url.host != nil, url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    static func appending(path: String, to baseURL: URL) -> URL {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedPath.isEmpty else { return baseURL }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let fullPath = ([basePath, trimmedPath].filter { !$0.isEmpty }).joined(separator: "/")
        components?.path = "/" + fullPath
        return components?.url ?? baseURL.appendingPathComponent(trimmedPath)
    }

    // No default server — the user configures one on first launch.
    static var defaultServerURL: String {
        ""
    }
}
