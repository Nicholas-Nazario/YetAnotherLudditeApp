import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var rules: [Rule] = []
    @Published private(set) var snapshot: RuleSnapshot?
    @Published private(set) var storageReady = true
    @Published var errorMessage: String?

    private let repository: RuleRepository
    private let restrictionService: RestrictionService
    private var evaluator: RuleEvaluator { RuleEvaluator(calendar: .current) }
    private let clock: () -> Date
    private var wallClockDate: Date

    var currentDate: Date { wallClockDate }

    init(
        repository: RuleRepository = JSONRuleRepository.appContainer(),
        restrictionService: RestrictionService = SimulatedRestrictionService(),
        clock: @escaping () -> Date = Date.init
    ) {
        self.clock = clock
        self.wallClockDate = clock()
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
        wallClockDate = clock()
        refreshSnapshot()
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
        guard PauseReview.isValidDuration(minutes) else {
            errorMessage = "Choose a pause from 15 minutes through 24 hours."
            return false
        }
        refreshClock()
        let saved = rules.first { $0.id == rule.id }
        if let reason = PauseReview.unavailableReason(for: saved, at: currentDate) {
            errorMessage = reason
            return false
        }
        guard var updated = saved else { return false }
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
            refreshClock()
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
            refreshClock()
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
