import Foundation

protocol RuleRepository {
    func load() throws -> [Rule]
    func save(_ rules: [Rule]) throws
    func deleteAll() throws
}

enum RuleRepositoryError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidRule

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "These local rules use a newer file format (version \(version)). Update the app to read them."
        case .invalidRule:
            return "The local rule file contains an invalid rule. The file was kept so it can be inspected or deleted."
        }
    }
}

struct JSONRuleRepository: RuleRepository {
    let fileURL: URL

    static func appContainer() -> JSONRuleRepository {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONRuleRepository(fileURL: support.appendingPathComponent("rules.json"))
    }

    func load() throws -> [Rule] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let envelope = try JSONDecoder().decode(RuleFile.self, from: data)
        guard envelope.version == RuleFile.currentVersion else {
            throw RuleRepositoryError.unsupportedVersion(envelope.version)
        }
        for rule in envelope.rules {
            guard rule.validationMessage() == nil,
                  rule.websites.allSatisfy({ pattern in
                      (try? DomainPattern.parse(pattern.host, scope: pattern.scope)) == pattern
                  }) else { throw RuleRepositoryError.invalidRule }
        }
        return envelope.rules
    }

    func save(_ rules: [Rule]) throws {
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try excludeFromBackup(folder)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(RuleFile(version: RuleFile.currentVersion, rules: rules))
        try data.write(to: fileURL, options: .atomic)
        try excludeFromBackup(fileURL)
    }

    func deleteAll() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}

private struct RuleFile: Codable {
    static let currentVersion = 1

    let version: Int
    let rules: [Rule]
}
