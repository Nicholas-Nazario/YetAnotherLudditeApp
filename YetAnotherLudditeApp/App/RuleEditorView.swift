import SwiftUI

struct RuleEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private let isEditing: Bool
    @State private var draft: Rule
    @State private var domainInput = ""
    @State private var domainScope: DomainScope = .includingSubdomains
    @State private var domainError: String?
    @State private var saveError: String?

    init(existingRule: Rule?) {
        isEditing = existingRule != nil
        _draft = State(initialValue: existingRule ?? Rule(
            name: "",
            schedule: WeeklySchedule(
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                start: ClockTime(hour: 9, minute: 0),
                end: ClockTime(hour: 17, minute: 0)
            )
        ))
    }

    var body: some View {
        Form {
            Section {
                SimulationBanner()
            }
            Section("Name") {
                TextField("Work Hours", text: $draft.name)
                    .textInputAutocapitalization(.words)
                Toggle("Enabled", isOn: $draft.isEnabled)
            }
            Section("Schedule") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Weekday.displayOrder) { day in
                            Toggle(day.shortName, isOn: Binding(
                                get: { draft.schedule.weekdays.contains(day) },
                                set: { selected in
                                    if selected { draft.schedule.weekdays.insert(day) }
                                    else { draft.schedule.weekdays.remove(day) }
                                }
                            ))
                            .toggleStyle(.button)
                        }
                    }
                }
                DatePicker("Start", selection: startTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: endTime, displayedComponents: .hourAndMinute)
                Text(draft.schedule.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("An overnight schedule belongs to the day it starts. Minimum duration: 15 minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Sample apps") {
                Text("These are examples for the Simulator, not apps installed on your phone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(SimulationCatalog.apps) { app in
                    Toggle(app.name, isOn: Binding(
                        get: { draft.sampleAppIDs.contains(app.id) },
                        set: { selected in
                            if selected { draft.sampleAppIDs.insert(app.id) }
                            else { draft.sampleAppIDs.remove(app.id) }
                        }
                    ))
                }
            }
            Section("Websites") {
                ForEach(draft.websites) { pattern in
                    HStack {
                        Text(pattern.label)
                        Spacer()
                        Button(role: .destructive) {
                            draft.websites.removeAll { $0 == pattern }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .accessibilityLabel("Remove \(pattern.label)")
                    }
                }
                TextField("youtube.com or *.youtube.com", text: $domainInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Picker("Match", selection: $domainScope) {
                    Text("Exact host").tag(DomainScope.exactHost)
                    Text("Include subdomains").tag(DomainScope.includingSubdomains)
                }
                if let preview = try? DomainPattern.parse(domainInput, scope: domainScope) {
                    Text(previewText(for: preview))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let domainError {
                    Text(domainError).font(.footnote).foregroundStyle(.red)
                }
                Button("Add website") { addWebsite() }
                Text("Website entries are previews only. Safari and Private Browsing are not restricted in Phase 0.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(isEditing ? "Edit Rule" : "New Rule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .alert("Could not save rule", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var startTime: Binding<Date> {
        Binding(
            get: { pickerDate(for: draft.schedule.start) },
            set: { draft.schedule.start = clockTime(from: $0) }
        )
    }

    private var endTime: Binding<Date> {
        Binding(
            get: { pickerDate(for: draft.schedule.end) },
            set: { draft.schedule.end = clockTime(from: $0) }
        )
    }

    private func pickerDate(for time: ClockTime) -> Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: time.hour, minute: time.minute)) ?? .now
    }

    private func clockTime(from date: Date) -> ClockTime {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ClockTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    private func previewText(for pattern: DomainPattern) -> String {
        if pattern.scope == .exactHost {
            return "Matches \(pattern.host) only. Other hosts, including sibling subdomains, are not included."
        }
        return "Matches \(pattern.host) and subdomains such as www.\(pattern.host) and m.\(pattern.host)."
    }

    private func addWebsite() {
        do {
            let pattern = try DomainPattern.parse(domainInput, scope: domainScope)
            guard !draft.websites.contains(pattern) else {
                domainError = "This website pattern is already in the rule."
                return
            }
            draft.websites.append(pattern)
            domainInput = ""
            domainError = nil
        } catch {
            domainError = error.localizedDescription
        }
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !domainInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveError = "Add the entered website or clear that field before saving."
            return
        }
        if let validation = draft.validationMessage() {
            saveError = validation
            return
        }
        if model.save(draft) {
            dismiss()
        } else {
            saveError = model.errorMessage
            model.errorMessage = nil
        }
    }
}
