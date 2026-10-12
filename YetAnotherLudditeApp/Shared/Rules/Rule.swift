import Foundation

enum Weekday: Int, CaseIterable, Codable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    static let displayOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var previous: Weekday {
        Weekday(rawValue: rawValue == 1 ? 7 : rawValue - 1)!
    }
}

struct ClockTime: Codable, Equatable, Hashable, Comparable {
    var hour: Int
    var minute: Int

    var minutesSinceMidnight: Int { hour * 60 + minute }

    var isValid: Bool { (0..<24).contains(hour) && (0..<60).contains(minute) }

    static func < (lhs: ClockTime, rhs: ClockTime) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }
}

struct WeeklySchedule: Codable, Equatable {
    var weekdays: Set<Weekday>
    var start: ClockTime
    var end: ClockTime

    var crossesMidnight: Bool { end < start }

    var durationMinutes: Int {
        (end.minutesSinceMidnight - start.minutesSinceMidnight + 1_440) % 1_440
    }

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let dayNumber = components.weekday,
              let day = Weekday(rawValue: dayNumber),
              let hour = components.hour,
              let minute = components.minute else { return false }

        let nowMinutes = hour * 60 + minute
        if crossesMidnight {
            return (weekdays.contains(day) && nowMinutes >= start.minutesSinceMidnight)
                || (weekdays.contains(day.previous) && nowMinutes < end.minutesSinceMidnight)
        }
        return weekdays.contains(day)
            && nowMinutes >= start.minutesSinceMidnight
            && nowMinutes < end.minutesSinceMidnight
    }

    var summary: String {
        let days = Weekday.displayOrder.filter { weekdays.contains($0) }
            .map(\.shortName).joined(separator: ", ")
        let startText = Self.timeFormatter.string(from: start.dateForDisplay)
        let endText = Self.timeFormatter.string(from: end.dateForDisplay)
        return "\(days), \(startText)–\(endText)\(crossesMidnight ? " next day" : "")"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private extension ClockTime {
    var dateForDisplay: Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: minute)) ?? .now
    }
}

struct Rule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var schedule: WeeklySchedule
    var sampleAppIDs: Set<String>
    var websites: [DomainPattern]
    var pauseUntil: Date?

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        schedule: WeeklySchedule,
        sampleAppIDs: Set<String> = [],
        websites: [DomainPattern] = [],
        pauseUntil: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.schedule = schedule
        self.sampleAppIDs = sampleAppIDs
        self.websites = websites
        self.pauseUntil = pauseUntil
    }

    func validationMessage() -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Give this rule a name."
        }
        if schedule.weekdays.isEmpty {
            return "Choose at least one day."
        }
        if !schedule.start.isValid || !schedule.end.isValid {
            return "Choose valid start and end times."
        }
        if schedule.durationMinutes < 15 {
            return "A schedule must last at least 15 minutes."
        }
        if sampleAppIDs.isEmpty && websites.isEmpty {
            return "Choose at least one sample app or website."
        }
        return nil
    }

    func isEffective(at date: Date, calendar: Calendar) -> Bool {
        guard isEnabled, schedule.contains(date, calendar: calendar) else { return false }
        return pauseUntil.map { $0 <= date } ?? true
    }
}
