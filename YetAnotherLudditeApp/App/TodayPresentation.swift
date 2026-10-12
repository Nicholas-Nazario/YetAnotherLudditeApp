import Foundation

enum TodayTone: Equatable {
    case active
    case paused
    case inactive
}

struct TodayTarget: Identifiable, Equatable {
    enum Kind: Equatable {
        case sampleApp(String)
        case website(DomainPattern)
    }

    let kind: Kind
    let name: String
    let ruleNames: [String]

    var id: String {
        switch kind {
        case .sampleApp(let id): return "app:\(id)"
        case .website(let pattern): return "website:\(pattern.id)"
        }
    }

    var typeDescription: String {
        switch kind {
        case .sampleApp: return "Sample app · example only"
        case .website(let pattern):
            return pattern.scope == .exactHost ? "Exact host" : "This domain and subdomains"
        }
    }

    var actionTitle: String {
        switch kind {
        case .sampleApp: return "Why restricted"
        case .website: return "Check host"
        }
    }

    var voiceOverDescription: String {
        let kindText: String
        switch kind {
        case .sampleApp: kindText = "sample app example"
        case .website(let pattern):
            kindText = pattern.scope == .exactHost
                ? "website, exact host"
                : "website, this domain and subdomains"
        }
        let reasons = ruleNames.joined(separator: ", ")
        return "\(name), \(kindText), would be restricted in simulation by \(ruleNames.count) \(ruleNames.count == 1 ? "rule" : "rules"): \(reasons)."
    }
}

struct TodayPresentation {
    let tone: TodayTone
    let statusLabel: String
    let title: String
    let detail: String
    let nextLabel: String
    let nextTitle: String
    let nextDetail: String
    let targets: [TodayTarget]
    let hasRules: Bool

    init(rules: [Rule], snapshot: RuleSnapshot, at date: Date, evaluator: RuleEvaluator = RuleEvaluator()) {
        hasRules = !rules.isEmpty
        let ruleNames = rules.reduce(into: [UUID: String]()) { result, rule in
            result[rule.id] = rule.name
        }
        let apps = snapshot.sampleAppReasons.keys.sorted().map { id in
            TodayTarget(
                kind: .sampleApp(id),
                name: SimulationCatalog.name(for: id),
                ruleNames: Self.names(for: snapshot.sampleAppReasons[id] ?? [], using: ruleNames)
            )
        }
        let websites = snapshot.websitePatternReasons.keys.sorted { $0.label < $1.label }.map { pattern in
            TodayTarget(
                kind: .website(pattern),
                name: pattern.host,
                ruleNames: Self.names(for: snapshot.websitePatternReasons[pattern] ?? [], using: ruleNames)
            )
        }
        targets = apps + websites

        let pausedNow = rules.filter { rule in
            rule.isEnabled && rule.schedule.contains(date, calendar: evaluator.calendar)
                && (rule.pauseUntil.map { $0 > date } ?? false)
        }.sorted { ($0.pauseUntil ?? .distantFuture) < ($1.pauseUntil ?? .distantFuture) }

        if rules.isEmpty {
            tone = .inactive
            statusLabel = "No rules"
            title = "A fresh start"
            detail = "Create a rule to see your boundaries here."
        } else if let pausedRule = pausedNow.first {
            tone = .paused
            statusLabel = "Paused"
            title = targets.isEmpty ? "Rules paused for now" : "\(targets.count) \(targets.count == 1 ? "target stays" : "targets stay") restricted"
            let until = pausedRule.pauseUntil?.formatted(date: .omitted, time: .shortened) ?? "later"
            let pauseText = pausedNow.count == 1
                ? "\(pausedRule.name) is paused until \(until)."
                : "\(pausedNow.count) scheduled rules are paused; the next returns around \(until)."
            if let overlap = Self.pausedAppOverlap(pausedNow: pausedNow, snapshot: snapshot, names: ruleNames) {
                detail = "\(pauseText) \(overlap)"
            } else if targets.isEmpty {
                detail = "\(pauseText) No targets would be restricted right now."
            } else {
                detail = "\(pauseText) Other active rules still apply to \(targets.count) \(targets.count == 1 ? "target" : "targets")."
            }
        } else if targets.isEmpty {
            tone = .inactive
            statusLabel = "Inactive"
            title = "Nothing restricted now"
            detail = "Your next scheduled window is shown below."
        } else {
            tone = .active
            statusLabel = "Active"
            title = "\(targets.count) \(targets.count == 1 ? "target would" : "targets would") be restricted"
            let activeNames = Self.names(for: snapshot.activeRuleIDs, using: ruleNames)
            if activeNames.count == 1 {
                detail = "\(activeNames[0]) is active in this simulation."
            } else if activeNames.count == 2 {
                detail = "\(activeNames[0]) and \(activeNames[1]) are active in this simulation."
            } else {
                detail = "\(activeNames.count) rules are active in this simulation."
            }
        }

        if rules.isEmpty {
            nextLabel = "SCHEDULE"
            nextTitle = "No changes scheduled"
            nextDetail = "Your next change will appear after you create a rule."
        } else if let next = snapshot.nextRuleChange {
            nextLabel = "NEXT EXPECTED CHANGE"
            let after = evaluator.snapshot(for: rules, at: next.addingTimeInterval(0.001))
            let started = after.activeRuleIDs.subtracting(snapshot.activeRuleIDs)
            let ended = snapshot.activeRuleIDs.subtracting(after.activeRuleIDs)
            let changeName: String
            if started.count == 1, ended.isEmpty, let id = started.first, let rule = rules.first(where: { $0.id == id }) {
                let resumed = rule.pauseUntil.map { abs($0.timeIntervalSince(next)) < 0.01 } ?? false
                changeName = "\(rule.name) \(resumed ? "resumes" : "begins")"
            } else if ended.count == 1, started.isEmpty, let id = ended.first, let name = ruleNames[id] {
                changeName = "\(name) ends"
            } else {
                changeName = "Rule change"
            }
            nextTitle = "\(next.formatted(date: .omitted, time: .shortened)) · \(changeName)"
            nextDetail = Self.changeDescription(before: snapshot, after: after, names: ruleNames)
        } else {
            nextLabel = "SCHEDULE"
            nextTitle = "No upcoming change"
            nextDetail = "Enable a scheduled rule to see its next expected change."
        }
    }

    private static func names(for IDs: Set<UUID>, using lookup: [UUID: String]) -> [String] {
        IDs.compactMap { lookup[$0] }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func pausedAppOverlap(
        pausedNow: [Rule], snapshot: RuleSnapshot, names: [UUID: String]
    ) -> String? {
        for rule in pausedNow {
            for id in rule.sampleAppIDs.sorted() {
                guard let remaining = snapshot.sampleAppReasons[id], !remaining.isEmpty else { continue }
                let responsible = Self.names(for: remaining, using: names).joined(separator: ", ")
                return "\(SimulationCatalog.name(for: id)) would stay restricted by \(responsible)."
            }
        }
        return nil
    }

    private static func changeDescription(
        before: RuleSnapshot, after: RuleSnapshot, names: [UUID: String]
    ) -> String {
        var changes: [String] = []
        for id in before.sampleAppReasons.keys.sorted() {
            guard let old = before.sampleAppReasons[id], let new = after.sampleAppReasons[id], old != new else { continue }
            changes.append("\(SimulationCatalog.name(for: id)) would stay restricted by \(Self.names(for: new, using: names).joined(separator: ", ")).")
        }
        for pattern in before.websitePatternReasons.keys.sorted(by: { $0.label < $1.label }) {
            guard let old = before.websitePatternReasons[pattern], let new = after.websitePatternReasons[pattern], old != new else { continue }
            changes.append("\(pattern.label) would stay restricted by \(Self.names(for: new, using: names).joined(separator: ", ")).")
        }

        let addedApps = Set(after.sampleAppReasons.keys).subtracting(before.sampleAppReasons.keys)
        let removedApps = Set(before.sampleAppReasons.keys).subtracting(after.sampleAppReasons.keys)
        let addedWebsites = Set(after.websitePatternReasons.keys).subtracting(before.websitePatternReasons.keys)
        let removedWebsites = Set(before.websitePatternReasons.keys).subtracting(after.websitePatternReasons.keys)
        let addedCount = addedApps.count + addedWebsites.count
        let removedCount = removedApps.count + removedWebsites.count

        if addedCount == 1, removedCount == 0 {
            if let id = addedApps.first { changes.append("\(SimulationCatalog.name(for: id)) would become restricted.") }
            if let pattern = addedWebsites.first { changes.append("\(pattern.label) would become restricted.") }
        } else if removedCount == 1, addedCount == 0 {
            if let id = removedApps.first { changes.append("\(SimulationCatalog.name(for: id)) would no longer be restricted.") }
            if let pattern = removedWebsites.first { changes.append("\(pattern.label) would no longer be restricted.") }
        } else {
            if addedCount > 0 { changes.append("\(addedCount) \(addedCount == 1 ? "target" : "targets") would become restricted.") }
            if removedCount > 0 { changes.append("\(removedCount) \(removedCount == 1 ? "target" : "targets") would no longer be restricted.") }
        }
        if changes.isEmpty { return "The active rules would change at this time." }
        if changes.count > 2 {
            return changes.prefix(2).joined(separator: " ") + " Other targets also change."
        }
        return changes.joined(separator: " ")
    }
}
