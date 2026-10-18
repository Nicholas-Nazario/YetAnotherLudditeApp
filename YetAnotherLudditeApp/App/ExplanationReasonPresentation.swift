import Foundation

struct ExplanationReasonPresentation {
    let reason: RestrictionReason
    let date: Date
    let calendar: Calendar

    var schedule: String {
        RulesRowPresentation(rule: reason.rule, date: date, calendar: calendar).schedule
    }

    var windowEnd: String {
        guard let end = reason.currentWindowEnd else { return "Current window end unavailable." }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = calendar.isDate(end, inSameDayAs: date) ? .none : .medium
        formatter.timeStyle = .short
        return "Current window ends \(formatter.string(from: end))."
    }

    var matchingExplanations: [String] {
        reason.matchingPatterns.map { pattern in
            pattern.scope == .includingSubdomains
                ? "Matches \(pattern.host) and its subdomains."
                : "Matches \(pattern.host) and its www version."
        }
    }
}
