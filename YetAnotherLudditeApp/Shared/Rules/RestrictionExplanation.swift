import Foundation

enum ExplanationTarget: Equatable {
    case sampleApp(String)
    case host(String)
}

struct RestrictionReason: Identifiable {
    let rule: Rule
    let currentWindowEnd: Date?
    let matchingPatterns: [DomainPattern]
    var id: UUID { rule.id }
}

/// A single evaluation date/calendar governs both membership and per-rule timing.
struct RestrictionExplanation {
    let target: ExplanationTarget
    let date: Date
    let calendar: Calendar
    let reasons: [RestrictionReason]

    init(target: ExplanationTarget, rules: [Rule], date: Date, calendar: Calendar) {
        self.target = target
        self.date = date
        self.calendar = calendar
        let evaluator = RuleEvaluator(calendar: calendar)
        let matching: [Rule]
        switch target {
        case .sampleApp(let id):
            matching = evaluator.blockingRules(forSampleApp: id, in: rules, at: date)
        case .host(let host):
            matching = evaluator.blockingRules(forHost: host, in: rules, at: date)
        }
        reasons = matching.map { rule in
            let patterns: [DomainPattern]
            if case .host(let host) = target {
                patterns = rule.websites.filter { $0.matches(host: host) }
            } else { patterns = [] }
            return RestrictionReason(
                rule: rule,
                currentWindowEnd: evaluator.snapshot(for: [rule], at: date).nextRuleChange,
                matchingPatterns: patterns
            )
        }
    }
}
