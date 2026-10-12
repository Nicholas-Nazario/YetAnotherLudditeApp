import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var rules: [Rule] = []
    @Published private(set) var snapshot: RuleSnapshot?
    @Published private(set) var storageReady = true
    @Published var previewDate: Date? {
        didSet { refreshSnapshot() }
    }
    @Published var errorMessage: String?

    private let repository: RuleRepository
    private let restrictionService: RestrictionService
    private let evaluator = RuleEvaluator()
    private var wallClockDate = Date()

    var currentDate: Date { previewDate ?? wallClockDate }

    init(
        repository: RuleRepository = JSONRuleRepository.appContainer(),
        restrictionService: RestrictionService = SimulatedRestrictionService()
    ) {
        self.repository = repository
        self.restrictionService = restrictionService
        do {
            rules = try repository.load()
        } catch {
            storageReady = false
            errorMessage = "Could not read local rules: \(error.localizedDescription)"
        }
        refreshSnapshot()
    }

    func refreshClock() {
        wallClockDate = Date()
        if previewDate == nil { refreshSnapshot() }
    }

    func save(_ rule: Rule) -> Bool {
        if let validation = rule.validationMessage() {
            errorMessage = validation
            return false
        }
        var updated = rules
        if let index = updated.firstIndex(where: { $0.id == rule.id }) {
            updated[index] = rule
        } else {
            updated.append(rule)
        }
        return commit(updated)
    }

    @discardableResult
    func delete(_ rule: Rule) -> Bool {
        commit(rules.filter { $0.id != rule.id })
    }

    func setEnabled(_ enabled: Bool, for rule: Rule) {
        var updated = rule
        updated.isEnabled = enabled
        _ = save(updated)
    }

    @discardableResult
    func pause(_ rule: Rule, minutes: Int) -> Bool {
        guard (15...1_440).contains(minutes) else {
            errorMessage = "Choose a pause from 15 minutes through 24 hours."
            return false
        }
        var updated = rule
        updated.pauseUntil = currentDate.addingTimeInterval(TimeInterval(minutes * 60))
        return save(updated)
    }

    func resume(_ rule: Rule) {
        var updated = rule
        updated.pauseUntil = nil
        _ = save(updated)
    }

    func resetLocalData() {
        do {
            try repository.deleteAll()
            rules = []
            storageReady = true
            refreshSnapshot()
        } catch {
            errorMessage = "Could not remove local rules: \(error.localizedDescription)"
        }
    }

    func blockingRules(forSampleApp id: String) -> [Rule] {
        evaluator.blockingRules(forSampleApp: id, in: rules, at: currentDate)
    }

    func blockingRules(forHost host: String) -> [Rule] {
        evaluator.blockingRules(forHost: host, in: rules, at: currentDate)
    }

    func otherBlockingRules(forSampleApp id: String, excluding rule: Rule) -> [Rule] {
        blockingRules(forSampleApp: id).filter { $0.id != rule.id }
    }

    func otherBlockingRules(forHost host: String, excluding rule: Rule) -> [Rule] {
        blockingRules(forHost: host).filter { $0.id != rule.id }
    }

    private func commit(_ updated: [Rule]) -> Bool {
        guard storageReady else {
            errorMessage = "The local rule file could not be read. Delete local data in Settings before creating new rules."
            return false
        }
        do {
            try repository.save(updated)
            rules = updated
            refreshSnapshot()
            return true
        } catch {
            errorMessage = "Could not save local rules: \(error.localizedDescription)"
            return false
        }
    }

    private func refreshSnapshot() {
        let newSnapshot = evaluator.snapshot(for: rules, at: currentDate)
        snapshot = newSnapshot
        restrictionService.apply(newSnapshot)
    }
}
