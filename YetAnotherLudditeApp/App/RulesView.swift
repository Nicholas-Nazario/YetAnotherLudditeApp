import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingEditor = false
    @State private var liveDate = Date()

    var body: some View {
        let calendar = Calendar.current
        List {
            Section {
                SimulationBanner()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            if model.rules.isEmpty {
                Section {
                    VStack(spacing: 6) {
                        Text("No rules yet").font(.headline)
                        Text("Rules let you set schedules for selected apps and websites.")
                            .font(.subheadline)
                            .foregroundStyle(Color("TodaySecondary"))
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                }
            } else {
                ForEach(RulesListState.allCases) { state in
                    let rules = model.rules.filter {
                        RulesListState.state(for: $0, at: liveDate, calendar: calendar) == state
                    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    if !rules.isEmpty {
                        Section {
                            ForEach(rules) { rule in
                                NavigationLink {
                                    RuleDetailView(ruleID: rule.id)
                                } label: {
                                    RulesListRow(presentation: RulesRowPresentation(rule: rule, date: liveDate, calendar: calendar))
                                }
                                .listRowInsets(EdgeInsets(top: 13, leading: 15, bottom: 13, trailing: 13))
                                .listRowSeparatorTint(Color("TodayLine"))
                                .listRowBackground(Color("TodayCard"))
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Text(state.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("TodayInk"))
                                Text(String(rules.count))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(state.foreground)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(state.background, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .textCase(nil)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(state.rawValue), \(rules.count) \(rules.count == 1 ? "rule" : "rules")")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color("TodayCanvas").ignoresSafeArea())
        .tint(Color("TodayBlue"))
        .navigationTitle("Rules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingEditor = true } label: {
                    Image(systemName: "plus").frame(minWidth: 44, minHeight: 44)
                }
                .tint(Color("TodayBlue"))
                .accessibilityLabel("Create rule")
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack { RuleEditorView(existingRule: nil) }
                .environmentObject(model)
        }
        .onAppear { liveDate = Date() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { liveDate = Date() }
        }
        .task(id: model.rules.map(\.pauseUntil)) {
            // Schedule ends occur on minute boundaries; pauses may expire between them.
            while !Task.isCancelled {
                let now = Date()
                liveDate = now
                let nextMinute = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 60) + 1) * 60)
                let nextPause = model.rules.compactMap(\.pauseUntil).filter { $0 > now }.min()
                let wake = min(nextMinute, nextPause ?? nextMinute)
                do {
                    try await Task.sleep(nanoseconds: UInt64(max(0.01, wake.timeIntervalSinceNow) * 1_000_000_000))
                } catch { return }
            }
        }
    }
}

private extension RulesListState {
    var foreground: Color {
        switch self {
        case .active: return Color("TodayActiveCore")
        case .paused: return Color("TodayPausedCore")
        case .upcoming, .disabled: return Color("TodayInactiveCore")
        }
    }

    var background: Color {
        switch self {
        case .active: return Color("TodayActiveSupport")
        case .paused: return Color("TodayPausedSupport")
        case .upcoming, .disabled: return Color("TodayInactiveSupport")
        }
    }
}

private struct RulesListRow: View {
    let presentation: RulesRowPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.rule.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("TodayInk"))
            Text(presentation.schedule)
            Text(presentation.targets)
            if let detail = presentation.detail {
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(presentation.state.foreground)
            }
        }
        .font(.caption)
        .foregroundStyle(Color("TodaySecondary"))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

struct RuleRow: View {
    let rule: Rule
    let now: Date

    private var status: String {
        if !rule.isEnabled { return "Disabled" }
        if let pauseUntil = rule.pauseUntil, pauseUntil > now {
            return "Paused until \(pauseUntil.formatted(date: .abbreviated, time: .shortened))"
        }
        return rule.schedule.contains(now, calendar: .current) ? "Active in simulation" : "Upcoming"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.name).font(.headline)
            Text(rule.schedule.summary).font(.subheadline)
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

struct RuleDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let ruleID: UUID
    @State private var showingEditor = false
    @State private var showingPause = false
    @State private var showingDeleteConfirmation = false

    private var rule: Rule? { model.rules.first(where: { $0.id == ruleID }) }

    var body: some View {
        Group {
            if let rule {
                List {
                    Section {
                        SimulationBanner()
                        RuleRow(rule: rule, now: model.currentDate)
                    }
                    Section("Sample apps") {
                        if rule.sampleAppIDs.isEmpty {
                            Text("None").foregroundStyle(.secondary)
                        } else {
                            ForEach(rule.sampleAppIDs.sorted(), id: \.self) { id in
                                NavigationLink(SimulationCatalog.name(for: id)) {
                                    WhyBlockedAppView(appID: id)
                                }
                            }
                        }
                    }
                    Section("Websites") {
                        if rule.websites.isEmpty {
                            Text("None").foregroundStyle(.secondary)
                        } else {
                            ForEach(rule.websites) { pattern in
                                NavigationLink(pattern.label) {
                                    WebsiteLookupView(initialHost: pattern.host)
                                }
                            }
                        }
                    }
                    Section("Actions") {
                        Button("Edit rule") { showingEditor = true }
                        if let pauseUntil = rule.pauseUntil, pauseUntil > model.currentDate {
                            Text("Paused until \(pauseUntil.formatted(date: .abbreviated, time: .shortened))")
                            Button("Resume now") { model.resume(rule) }
                        } else {
                            Button("Pause rule") { showingPause = true }
                        }
                        Button(rule.isEnabled ? "Disable rule" : "Enable rule") {
                            model.setEnabled(!rule.isEnabled, for: rule)
                        }
                        Button("Delete rule", role: .destructive) { showingDeleteConfirmation = true }
                    }
                }
            } else {
                Text("This rule has been deleted.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(rule?.name ?? "Rule")
        .sheet(isPresented: $showingEditor) {
            if let rule {
                NavigationStack { RuleEditorView(existingRule: rule) }
                    .environmentObject(model)
            }
        }
        .sheet(isPresented: $showingPause) {
            if let rule {
                NavigationStack { PauseRuleView(rule: rule) }
                    .environmentObject(model)
            }
        }
        .confirmationDialog("Delete this rule?", isPresented: $showingDeleteConfirmation) {
            Button("Delete rule", role: .destructive) {
                if let rule, model.delete(rule) {
                    dismiss()
                }
            }
        } message: {
            Text("This removes the local rule and its simulated restrictions.")
        }
    }
}
