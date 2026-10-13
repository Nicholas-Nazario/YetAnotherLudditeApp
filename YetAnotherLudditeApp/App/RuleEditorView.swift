import SwiftUI
import UIKit

struct RuleEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @ScaledMetric(relativeTo: .caption) private var dayDiameter = 39
    private let isEditing: Bool
    private let initialDraft: Rule
    @State private var draft: Rule
    @State private var domainInput = ""
    @State private var domainScope: DomainScope = .exactHost
    @State private var domainError: String?
    @State private var didValidate = false
    @State private var saveError: String?
    @State private var confirmingDiscard = false
    @FocusState private var inputFocus: Field?
    @AccessibilityFocusState private var accessibilityFocus: Field?

    private enum Field: Hashable { case name, days, times, targets, website, day(Weekday), app(String) }

    init(existingRule: Rule?) {
        isEditing = existingRule != nil
        let rule = existingRule ?? Rule(name: "", schedule: WeeklySchedule(
            weekdays: [], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 17, minute: 0)
        ))
        initialDraft = rule
        _draft = State(initialValue: rule)
    }

    private var isDirty: Bool { draft != initialDraft || !domainInput.isEmpty || domainScope != .exactHost }
    private var errors: [Rule.ValidationField: String] { didValidate ? draft.validationErrors : [:] }
    private var websiteError: String? {
        domainError ?? (didValidate && !domainInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Add this website or clear the field before saving." : nil)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    SimulationBanner()
                    section("Name") {
                        card {
                            TextField("Rule name", text: $draft.name)
                                .textInputAutocapitalization(.words)
                                .focused($inputFocus, equals: .name)
                                .accessibilityLabel("Rule name")
                                .accessibilityHint(errors[.name] ?? "")
                                .accessibilityFocused($accessibilityFocus, equals: .name)
                                .frame(minHeight: 44).id(Field.name)
                            errorLabel(errors[.name])
                            Divider()
                            Toggle("Enabled", isOn: $draft.isEnabled).frame(minHeight: 44)
                        }
                    }
                    section("Schedule") {
                        card {
                            weekdayPicker
                            .id(Field.days)
                            helper(draft.schedule.weekdays.isEmpty ? "Choose at least one day" : draft.schedule.summary)
                            errorLabel(errors[.days])
                            timePicker("Starts", selection: startTime)
                                .frame(minHeight: 44).padding(.top, 8).id(Field.times)
                                .accessibilityHint(errors[.times] ?? "")
                                .accessibilityFocused($accessibilityFocus, equals: .times)
                            Divider()
                            timePicker("Ends", selection: endTime)
                                .frame(minHeight: 44)
                            errorLabel(errors[.times])
                            helper("Overnight schedules belong to the day they start. Minimum duration: 15 minutes.")
                                .padding(.top, 8)
                        }
                    }
                    section("Targets") {
                        Text("Apps").font(.subheadline.weight(.semibold)).id(Field.targets)
                        helper("These are examples for the Simulator, not apps installed on your phone.")
                        card {
                            ForEach(SimulationCatalog.apps) { app in
                                let selected = draft.sampleAppIDs.contains(app.id)
                                Button {
                                    if selected { draft.sampleAppIDs.remove(app.id) }
                                    else { draft.sampleAppIDs.insert(app.id) }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: app.symbol).frame(width: 32, height: 32)
                                            .foregroundStyle(Color("TodayPurple"))
                                        Text(app.name).foregroundStyle(Color("TodayInk"))
                                        Spacer(minLength: 8)
                                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    }.frame(minHeight: 44).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityFocused($accessibilityFocus, equals: app.id == SimulationCatalog.apps.first?.id ? .targets : .app(app.id))
                                .accessibilityLabel(app.name)
                                .accessibilityValue(selected ? "Selected" : "Not selected")
                                .accessibilityAddTraits(selected ? [.isSelected] : [])
                                if app.id != SimulationCatalog.apps.last?.id { Divider() }
                            }
                        }
                        errorLabel(errors[.targets])
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Websites").font(.subheadline.weight(.semibold))
                                helper("\(draft.websites.count) websites added")
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Websites").font(.subheadline.weight(.semibold))
                                helper("\(draft.websites.count) websites added")
                            }
                        }.padding(.top, 10)
                        if !draft.websites.isEmpty {
                            card {
                                ForEach(draft.websites) { pattern in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(pattern.host).font(.subheadline.weight(.semibold))
                                            helper(pattern.scope == .exactHost ? "This website" : "All subdomains")
                                        }
                                        Spacer(minLength: 0)
                                        Button(role: .destructive) {
                                            draft.websites.removeAll { $0 == pattern }
                                        } label: {
                                            Image(systemName: "minus.circle").frame(width: 44, height: 44)
                                        }
                                        .accessibilityLabel("Remove \(pattern.host)")
                                    }
                                    if pattern.id != draft.websites.last?.id { Divider() }
                                }
                            }
                        }
                        card {
                            TextField("www.youtube.com", text: $domainInput)
                                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                                .focused($inputFocus, equals: .website)
                                .accessibilityLabel("Website address")
                                .accessibilityHint(websiteError ?? "")
                                .accessibilityFocused($accessibilityFocus, equals: .website)
                                .frame(minHeight: 44).id(Field.website)
                                .onSubmit { addWebsite() }
                            errorLabel(websiteError)
                            Divider()
                            Text("Match").font(.footnote.weight(.semibold))
                            if textSize.isAccessibilitySize {
                                matchPicker.pickerStyle(.menu).frame(minHeight: 44)
                            } else {
                                matchPicker.pickerStyle(.segmented).frame(minHeight: 44)
                            }
                            helper(previewText)
                            Divider()
                            Button("Add website") { addWebsite() }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("TodayBlue"))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        helper("Website entries are previews only. Safari and Private Browsing are not restricted in Phase 0.")
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { requestCancel() }.foregroundStyle(Color("TodayBlue")) }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save(proxy: proxy) }.foregroundStyle(Color("TodayBlue")) }
            }
        }
        .font(.subheadline)
        .foregroundStyle(Color("TodayInk"))
        .background(Color("TodayCanvas").ignoresSafeArea())
        .tint(Color("TodayBlue"))
        .navigationTitle(isEditing ? "Edit Rule" : "New Rule")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isDirty)
        .background(EditorDismissGuard(isDirty: isDirty, onAttempt: requestCancel))
        .onChange(of: domainInput) { _ in domainError = nil }
        .onChange(of: domainScope) { _ in domainError = nil }
        .alert("Discard unsaved changes?", isPresented: $confirmingDiscard) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard Changes", role: .destructive) { dismiss() }
        } message: { Text("Your changes to this rule will be lost.") }
        .alert("Could not save rule", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK", role: .cancel) { saveError = nil } }
        message: { Text(saveError ?? "") }
    }

    @ViewBuilder private var weekdayPicker: some View {
        if textSize.isAccessibilitySize {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 12) {
                weekdayButtons
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 2) { weekdayButtons }
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 2) { weekdayButtons }
                }
            }
        }
    }

    private var weekdayButtons: some View {
            ForEach(Weekday.displayOrder) { day in
                let selected = draft.schedule.weekdays.contains(day)
                Button {
                    if selected { draft.schedule.weekdays.remove(day) }
                    else { draft.schedule.weekdays.insert(day) }
                } label: {
                    Text(String(day.shortName.prefix(1)))
                        .font(.caption.weight(.bold))
                        .frame(width: min(dayDiameter, 72), height: min(dayDiameter, 72))
                        .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color("TodaySecondary"))
                        .background(selected ? Color("TodayBlue") : Color("TodayCard"), in: Circle())
                        .overlay(Circle().stroke(selected ? Color("TodayBlue") : Color("TodayLine"), lineWidth: 1))
                        .overlay(alignment: .bottomTrailing) {
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color("TodayBlue"))
                                    .background(Color("TodayCard"), in: Circle())
                            }
                        }
                        .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityFocused($accessibilityFocus, equals: day == .monday ? .days : .day(day))
                .accessibilityLabel(Calendar.current.weekdaySymbols[day.rawValue - 1])
                .accessibilityValue(selected ? "Selected" : "Not selected")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).padding(.horizontal, 3)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("TodayLine"), lineWidth: 1))
    }

    private func helper(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(Color("TodaySecondary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func errorLabel(_ message: String?) -> some View {
        if let message {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.footnote).foregroundStyle(Color("TodayErrorText"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private func timePicker(_ title: String, selection: Binding<Date>) -> some View {
        if textSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        } else {
            DatePicker(title, selection: selection, displayedComponents: .hourAndMinute)
        }
    }

    private var startTime: Binding<Date> {
        Binding(get: { pickerDate(for: draft.schedule.start) }, set: { draft.schedule.start = clockTime(from: $0) })
    }
    private var endTime: Binding<Date> {
        Binding(get: { pickerDate(for: draft.schedule.end) }, set: { draft.schedule.end = clockTime(from: $0) })
    }
    private func pickerDate(for time: ClockTime) -> Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: time.hour, minute: time.minute)) ?? Date(timeIntervalSince1970: 0)
    }
    private func clockTime(from date: Date) -> ClockTime {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ClockTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
    private var matchPicker: some View {
        Picker("Match", selection: $domainScope) {
            Text("This website").tag(DomainScope.exactHost)
            Text("All subdomains").tag(DomainScope.includingSubdomains)
        }
    }

    private var previewText: String {
        let pattern = try? composerPattern()
        let host = pattern?.host ?? "youtube.com"
        return domainScope == .exactHost
            ? "Includes \(host) and its www version. Other subdomains, such as m.\(host), are not included."
            : "Matches \(host) and all subdomains, such as m.\(host)."
    }
    private func composerPattern() throws -> DomainPattern {
        guard !domainInput.contains("*") else { throw DomainInputError.invalid }
        return try DomainPattern.parse(domainInput, scope: domainScope)
    }
    private func addWebsite() {
        do {
            let pattern = try composerPattern()
            guard !draft.websites.contains(where: {
                (try? DomainPattern.parse($0.host, scope: $0.scope)) == pattern
            }) else {
                domainError = "This website and matching scope are already in the rule."
                inputFocus = .website
                return
            }
            draft.websites.append(pattern)
            domainInput = ""
            domainError = nil
        } catch {
            domainError = error.localizedDescription
            inputFocus = .website
            accessibilityFocus = .website
            UIAccessibility.post(notification: .announcement, argument: domainError)
        }
    }
    private func requestCancel() {
        if isDirty { confirmingDiscard = true } else { dismiss() }
    }
    private func save(proxy: ScrollViewProxy) {
        didValidate = true
        let validation = draft.validationErrors
        let first: Field?
        if validation[.name] != nil { first = .name }
        else if validation[.days] != nil { first = .days }
        else if validation[.times] != nil { first = .times }
        else if validation[.targets] != nil { first = .targets }
        else if websiteError != nil { first = .website }
        else { first = nil }
        if let first {
            inputFocus = nil
            withAnimation { proxy.scrollTo(first, anchor: .top) }
            UIAccessibility.post(notification: .announcement, argument:
                Rule.ValidationField.allCases.compactMap { validation[$0] }.joined(separator: " ") + " " + (websiteError ?? ""))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if first == .name || first == .website { inputFocus = first }
                accessibilityFocus = first
            }
            return
        }
        var saved = draft
        saved.name = saved.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if model.save(saved) { dismiss() }
        else { saveError = model.errorMessage; model.errorMessage = nil }
    }
}

/// Intercepts attempted sheet swipes so they use the same discard confirmation as Cancel.
private struct EditorDismissGuard: UIViewControllerRepresentable {
    var isDirty: Bool
    var onAttempt: () -> Void

    func makeUIViewController(context: Context) -> GuardController { GuardController() }
    func updateUIViewController(_ controller: GuardController, context: Context) {
        controller.isDirty = isDirty
        controller.onAttempt = onAttempt
        controller.installDelegate()
    }

    final class GuardController: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isDirty = false
        var onAttempt: (() -> Void)?
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installDelegate()
        }
        func installDelegate() {
            var presented: UIViewController = self
            while let parent = presented.parent { presented = parent }
            presented.presentationController?.delegate = self
        }
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool { !isDirty }
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) { onAttempt?() }
    }
}
