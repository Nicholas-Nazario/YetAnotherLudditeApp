import Foundation

/// List status is evaluated with an explicit live date, using the current device time.
enum RulesListState: String, CaseIterable, Identifiable {
    case active = "Active"
    case paused = "Paused"
    case upcoming = "Upcoming"
    case disabled = "Disabled"

    var id: String { rawValue }

    static func state(for rule: Rule, at date: Date, calendar: Calendar) -> Self {
        if !rule.isEnabled { return .disabled }
        if let expiry = rule.pauseUntil, expiry > date { return .paused }
        return rule.schedule.contains(date, calendar: calendar) ? .active : .upcoming
    }
}

struct RulesRowPresentation {
    let rule: Rule
    let date: Date
    let calendar: Calendar

    var state: RulesListState { .state(for: rule, at: date, calendar: calendar) }

    var schedule: String {
        "\(days), \(timeRange)"
    }

    var timeRange: String {
        "\(time(rule.schedule.start))–\(time(rule.schedule.end))\(rule.schedule.crossesMidnight ? " next day" : "")"
    }

    var days: String {
        let selected = Weekday.displayOrder.filter { rule.schedule.weekdays.contains($0) }
        let days: String
        switch rule.schedule.weekdays {
        case Set(Weekday.allCases): days = "Every day"
        case Set([.monday, .tuesday, .wednesday, .thursday, .friday]): days = "Weekdays"
        case Set([.saturday, .sunday]): days = "Weekends"
        default:
            let indices = selected.compactMap { Weekday.displayOrder.firstIndex(of: $0) }
            let names = selected.map { calendar.shortWeekdaySymbols[$0.rawValue - 1] }
            if indices.count > 1, let first = indices.first, let last = indices.last,
               last - first + 1 == indices.count {
                days = "\(names.first!)–\(names.last!)"
            } else {
                days = names.joined(separator: ", ")
            }
        }
        return days
    }

    var targets: String {
        let apps = rule.sampleAppIDs.count
        let sites = rule.websites.count
        return "\(apps) \(apps == 1 ? "app" : "apps") · \(sites) \(sites == 1 ? "website" : "websites")"
    }

    var detail: String? {
        switch state {
        case .active:
            // For one active rule, its next effective-state change is its current window's end.
            guard let end = RuleEvaluator(calendar: calendar).snapshot(for: [rule], at: date).nextRuleChange else { return nil }
            let minutes = max(1, Int(ceil(end.timeIntervalSince(date) / 60)))
            let hours = minutes / 60
            let remainder = minutes % 60
            let remaining = hours == 0 ? "\(minutes)m" : remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
            return "Ends in \(remaining)"
        case .paused:
            guard let expiry = rule.pauseUntil else { return nil }
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Paused until \(formatter.string(from: expiry))"
        case .upcoming, .disabled: return nil
        }
    }

    private func time(_ clock: ClockTime) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.timeStyle = .short
        // A fixed date keeps schedule formatting independent of the evaluation date.
        let components = DateComponents(year: 2000, month: 1, day: 1, hour: clock.hour, minute: clock.minute)
        guard let value = calendar.date(from: components) else { return "" }
        return formatter.string(from: value)
    }
}

/// Detail copy uses the same effective-state evaluator as the Rules list.
struct RuleDetailPresentation {
    let rule: Rule
    let date: Date
    let calendar: Calendar

    var state: RulesListState { .state(for: rule, at: date, calendar: calendar) }

    var explanation: String {
        switch state {
        case .disabled: return "This rule does not apply until you enable it."
        case .paused: return "Paused until \(formatted(rule.pauseUntil!))."
        case .upcoming: return "Outside its scheduled hours."
        case .active:
            let apps = rule.sampleAppIDs.count
            let sites = rule.websites.count
            return "This rule would restrict \(apps) \(apps == 1 ? "app" : "apps") and \(sites) \(sites == 1 ? "website" : "websites")."
        }
    }

    var nextChange: String {
        switch state {
        case .disabled:
            if let expiry = rule.pauseUntil, expiry > date {
                return "A pause is retained until \(formatted(expiry)). Enabling before then keeps this rule paused."
            }
            return "Enable this rule to use its schedule."
        case .active:
            return transition(after: date).map { "Ends \(formatted($0))." } ?? ""
        case .upcoming:
            return transition(after: date).map { "Starts \(formatted($0))." } ?? ""
        case .paused:
            let expiry = rule.pauseUntil!
            if rule.schedule.contains(expiry, calendar: calendar) {
                let end = transition(after: expiry).map { " This window ends \(formatted($0))." } ?? ""
                return "Scheduled restrictions resume \(formatted(expiry))." + end
            }
            return transition(after: expiry).map {
                "The pause expires outside scheduled hours. Scheduled restrictions next start \(formatted($0))."
            } ?? "The pause expires outside scheduled hours."
        }
    }

    private func transition(after value: Date) -> Date? {
        var scheduledRule = rule
        scheduledRule.isEnabled = true
        scheduledRule.pauseUntil = nil
        return RuleEvaluator(calendar: calendar).snapshot(for: [scheduledRule], at: value).nextRuleChange
    }

    private func formatted(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }
}
