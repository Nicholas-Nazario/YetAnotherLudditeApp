import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingEditor = false

    var body: some View {
        List {
            Section {
                SimulationBanner()
            }
            if model.rules.isEmpty {
                Section {
                    Text("Create a rule to preview when sample apps and Safari domains would be blocked.")
                        .foregroundStyle(.secondary)
                    Button("Create rule") { showingEditor = true }
                }
            } else {
                Section("Your rules") {
                    ForEach(model.rules) { rule in
                        NavigationLink {
                            RuleDetailView(ruleID: rule.id)
                        } label: {
                            RuleRow(rule: rule, now: model.currentDate)
                        }
                    }
                }
            }
        }
        .navigationTitle("Rules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingEditor = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Create rule")
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack { RuleEditorView(existingRule: nil) }
                .environmentObject(model)
        }
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
