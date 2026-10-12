import Foundation

enum DomainScope: String, Codable, CaseIterable {
    case exactHost
    case includingSubdomains
}

struct DomainPattern: Codable, Hashable, Identifiable {
    var host: String
    var scope: DomainScope

    var id: String { "\(scope.rawValue):\(host)" }

    var label: String {
        scope == .exactHost ? host : "\(host) and subdomains"
    }

    func matches(host candidate: String) -> Bool {
        let normalized = candidate.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if normalized == host { return true }
        return scope == .includingSubdomains && normalized.hasSuffix(".\(host)")
    }

    static func parse(_ input: String, scope requestedScope: DomainScope) throws -> DomainPattern {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw DomainInputError.empty }

        var scope = requestedScope
        if value.hasPrefix("*.") {
            value.removeFirst(2)
            scope = .includingSubdomains
        }

        let urlText = value.contains("://") ? value : "https://\(value)"
        guard let parts = URLComponents(string: urlText),
              parts.user == nil, parts.password == nil,
              let rawHost = parts.host else { throw DomainInputError.invalid }

        let host = rawHost.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2,
              host.utf8.count <= 253,
              labels.allSatisfy({ label in
                  !label.isEmpty && label.utf8.count <= 63
                      && label.first != "-" && label.last != "-"
                      && label.utf8.allSatisfy({ byte in
                          (97...122).contains(byte) || (48...57).contains(byte) || byte == 45
                      })
              }) else { throw DomainInputError.invalid }

        return DomainPattern(host: host, scope: scope)
    }
}

enum DomainInputError: LocalizedError {
    case empty
    case invalid

    var errorDescription: String? {
        switch self {
        case .empty: return "Enter a website domain."
        case .invalid: return "Enter a valid domain, such as youtube.com. Use ASCII or Punycode for international domains."
        }
    }
}
