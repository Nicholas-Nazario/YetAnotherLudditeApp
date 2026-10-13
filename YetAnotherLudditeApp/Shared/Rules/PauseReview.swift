import Foundation

/// Consequences are evaluated at the caller's date, never at sheet-opening time.
struct PauseReview {
    let rule: Rule
    let rules: [Rule]
    let date: Date
    let calendar: Calendar

    static func unavailableReason(for rule: Rule?, at date: Date) -> String? {
        guard let rule else { return "This rule has been deleted. Return to Rule details." }
        guard rule.isEnabled else { return "This rule is disabled and cannot be paused. Return to Rule details." }
        if let expiry = rule.pauseUntil, expiry > date {
            return "This rule is already paused. Return to Rule details to review its pause."
        }
        if rule.validationMessage() != nil {
            return "This rule needs a valid schedule and at least one target before it can be paused."
        }
        return nil
    }

    static func isValidDuration(_ minutes: Int) -> Bool { (15...1_440).contains(minutes) }

    var changesNow: Bool { rule.isEffective(at: date, calendar: calendar) }

    private var others: [Rule] { rules.filter { $0.id != rule.id } }
    private var evaluator: RuleEvaluator { RuleEvaluator(calendar: calendar) }

    func appReasons(_ id: String) -> [Rule] {
        evaluator.blockingRules(forSampleApp: id, in: others, at: date)
    }

    func hostReasons(_ host: String) -> [Rule] {
        evaluator.blockingRules(forHost: host, in: others, at: date)
    }

    var releasedAppCount: Int {
        changesNow ? rule.sampleAppIDs.filter { appReasons($0).isEmpty }.count : 0
    }

    var retainedAppCount: Int {
        changesNow ? rule.sampleAppIDs.count - releasedAppCount : 0
    }

    /// These are concrete examples, not a statement about an entire wildcard scope.
    func exampleHosts(for pattern: DomainPattern) -> [String] {
        [pattern.host, "www.\(pattern.host)"]
            + (pattern.scope == .includingSubdomains ? ["m.\(pattern.host)"] : [])
    }

    func exampleHostGroups(for pattern: DomainPattern) -> [[String]] {
        let hosts = exampleHosts(for: pattern)
        let baseReasons = hostReasons(hosts[0])
        let wwwReasons = hostReasons(hosts[1])
        let sameScopes = baseReasons.allSatisfy { reason in
            reason.websites.filter { $0.matches(host: hosts[0]) }
                == reason.websites.filter { $0.matches(host: hosts[1]) }
        }
        if baseReasons == wwwReasons && sameScopes {
            return [Array(hosts.prefix(2))] + hosts.dropFirst(2).map { [$0] }
        }
        return hosts.map { [$0] }
    }

    func nextApplication(after expiry: Date) -> Date? {
        if rule.schedule.contains(expiry, calendar: calendar) { return expiry }
        var scheduled = rule
        scheduled.isEnabled = true
        scheduled.pauseUntil = nil
        return evaluator.snapshot(for: [scheduled], at: expiry).nextRuleChange
    }

    func scheduleConsequence(minutes: Int) -> String {
        let expiry = date.addingTimeInterval(TimeInterval(minutes * 60))
        if !changesNow,
           let start = evaluator.snapshot(for: [rule], at: date).nextRuleChange,
           expiry <= start {
            return "The next scheduled start stays \(formatted(start)). This pause ends by then."
        }
        if rule.schedule.contains(expiry, calendar: calendar) {
            return changesNow
                ? "This rule’s simulated restrictions would resume then. Other rules still apply."
                : "The next scheduled start falls within this pause. Simulated restrictions would begin when the pause ends."
        }
        guard let start = nextApplication(after: expiry) else {
            return "The schedule is inactive when this pause ends."
        }
        return "The schedule is inactive when this pause ends. Next scheduled start: \(formatted(start))."
    }

    func formatted(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = calendar.isDate(value, inSameDayAs: date) ? .none : .medium
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }

    func responsibility(_ responsible: Rule, host: String? = nil) -> String {
        let end = evaluator.snapshot(for: [responsible], at: date).nextRuleChange
        var text = responsible.name
        if let end { text += " until \(formatted(end))" }
        if let host {
            let scopes = responsible.websites.filter { $0.matches(host: host) }.map {
                "\($0.host) · \($0.scope == .exactHost ? "This website" : "All subdomains")"
            }
            text += " (\(scopes.joined(separator: "; ")))"
        }
        return text
    }
}
