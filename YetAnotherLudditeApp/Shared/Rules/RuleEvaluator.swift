import Foundation

struct RuleSnapshot {
    let asOf: Date
    let activeRuleIDs: Set<UUID>
    let sampleAppReasons: [String: Set<UUID>]
    let websitePatternReasons: [DomainPattern: Set<UUID>]
    let nextRuleChange: Date?

    var isEmpty: Bool {
        sampleAppReasons.isEmpty && websitePatternReasons.isEmpty
    }
}

struct RuleEvaluator {
    var calendar: Calendar = .current

    func snapshot(for rules: [Rule], at date: Date) -> RuleSnapshot {
        let active = rules.filter { $0.isEffective(at: date, calendar: calendar) }
        var appReasons: [String: Set<UUID>] = [:]
        var websiteReasons: [DomainPattern: Set<UUID>] = [:]

        for rule in active {
            for appID in rule.sampleAppIDs {
                appReasons[appID, default: []].insert(rule.id)
            }
            for website in rule.websites {
                websiteReasons[website, default: []].insert(rule.id)
            }
        }

        return RuleSnapshot(
            asOf: date,
            activeRuleIDs: Set(active.map(\.id)),
            sampleAppReasons: appReasons,
            websitePatternReasons: websiteReasons,
            nextRuleChange: nextChange(for: rules, after: date)
        )
    }

    func blockingRules(forSampleApp appID: String, in rules: [Rule], at date: Date) -> [Rule] {
        rules.filter { $0.sampleAppIDs.contains(appID) && $0.isEffective(at: date, calendar: calendar) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func blockingRules(forHost host: String, in rules: [Rule], at date: Date) -> [Rule] {
        rules.filter { rule in
            rule.isEffective(at: date, calendar: calendar)
                && rule.websites.contains(where: { $0.matches(host: host) })
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func nextChange(for rules: [Rule], after date: Date) -> Date? {
        let enabledRules = rules.filter(\.isEnabled)
        guard !enabledRules.isEmpty else { return nil }

        let today = calendar.startOfDay(for: date)
        var candidates = Set<Date>()

        for rule in enabledRules {
            if let pauseUntil = rule.pauseUntil, pauseUntil > date {
                candidates.insert(pauseUntil)
            }

            for offset in -1...8 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                      let weekdayNumber = calendar.dateComponents([.weekday], from: day).weekday,
                      let weekday = Weekday(rawValue: weekdayNumber),
                      rule.schedule.weekdays.contains(weekday) else { continue }

                if let start = self.date(on: day, at: rule.schedule.start), start > date {
                    candidates.insert(start)
                }

                let endDay = rule.schedule.crossesMidnight
                    ? calendar.date(byAdding: .day, value: 1, to: day)
                    : day
                if let endDay,
                   let end = self.date(on: endDay, at: rule.schedule.end),
                   end > date {
                    candidates.insert(end)
                }
            }
        }

        for candidate in candidates.sorted() {
            let before = Set(enabledRules.filter {
                $0.isEffective(at: candidate.addingTimeInterval(-1), calendar: calendar)
            }.map(\.id))
            let after = Set(enabledRules.filter {
                $0.isEffective(at: candidate, calendar: calendar)
            }.map(\.id))
            if before != after { return candidate }
        }
        return nil
    }

    private func date(on day: Date, at time: ClockTime) -> Date? {
        calendar.date(
            bySettingHour: time.hour,
            minute: time.minute,
            second: 0,
            of: day,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }
}
