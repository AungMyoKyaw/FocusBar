#if !MAC_APP_STORE
import Foundation

enum UpdateCheckResult: Equatable {
    case upToDate(current: String)
    case updateAvailable(latest: String, releaseURL: URL)
    case failed(String)
}

struct GitHubReleasePayload: Decodable {
    let tagName: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}

final class UpdateCheckService {
    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let cleanCandidate = parseSemver(candidate)
        let cleanCurrent = parseSemver(current)
        let count = max(cleanCandidate.count, cleanCurrent.count)
        for idx in 0..<count {
            let a = idx < cleanCandidate.count ? cleanCandidate[idx] : 0
            let b = idx < cleanCurrent.count ? cleanCurrent[idx] : 0
            if a != b { return a > b }
        }
        return false
    }

    private static func parseSemver(_ raw: String) -> [Int] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "v", with: "", options: [.anchored, .caseInsensitive])
        let core = trimmed.split(separator: "-").first.map(String.init) ?? trimmed
        return core.split(separator: ".").compactMap { Int($0) }
    }

    func checkForUpdates(currentVersion: String = Constants.appVersion) async -> UpdateCheckResult {
        guard let url = URL(string: Constants.releasesAPIURL) else {
            return .failed("Invalid releases URL")
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return .failed("GitHub returned HTTP \(http.statusCode)")
            }
            let payload = try JSONDecoder().decode(GitHubReleasePayload.self, from: data)
            let cleanLatest = payload.tagName.replacingOccurrences(of: "v", with: "", options: [.anchored, .caseInsensitive])
            if Self.isVersion(cleanLatest, newerThan: currentVersion),
               let releaseURL = URL(string: payload.htmlUrl) {
                return .updateAvailable(latest: payload.tagName, releaseURL: releaseURL)
            }
            return .upToDate(current: currentVersion)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
#endif
