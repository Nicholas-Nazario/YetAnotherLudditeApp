import Foundation

struct SampleApp: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
}

enum SimulationCatalog {
    static let apps: [SampleApp] = [
        SampleApp(id: "demo.app.a", name: "Sample App A", symbol: "play.rectangle"),
        SampleApp(id: "demo.app.b", name: "Sample App B", symbol: "bubble.left.and.bubble.right"),
        SampleApp(id: "demo.app.c", name: "Sample App C", symbol: "gamecontroller")
    ]

    static func name(for id: String) -> String {
        apps.first(where: { $0.id == id })?.name ?? "Unknown sample app"
    }
}

protocol RestrictionService: AnyObject {
    func apply(_ snapshot: RuleSnapshot)
}

final class SimulatedRestrictionService: RestrictionService {
    private(set) var lastSnapshot: RuleSnapshot?

    func apply(_ snapshot: RuleSnapshot) {
        lastSnapshot = snapshot
    }
}
