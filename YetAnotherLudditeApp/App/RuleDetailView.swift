import SwiftUI

struct RuleDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let ruleID: UUID
    @State private var showingEditor = false
    @State private var showingPause = false
    @State private var showingDeleteConfirmation = false

    private var rule: Rule? { model.rules.first { $0.id == ruleID } }

    var body: some View {
        ScrollView {
            if let rule {
                content(rule)
            } else {
                VStack(spacing: 12) {
                    Text("This rule has been deleted.")
                    Button("Back to Rules") { dismiss() }
                        .frame(minHeight: 44)
                }
                .padding(20)
            }
        }
        .background(Color("TodayCanvas").ignoresSafeArea())
        .foregroundStyle(Color("TodayInk"))
        .tint(Color("TodayBlue"))
        .navigationTitle("Rule details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if rule != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showingEditor = true }
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .onAppear { model.refreshClock() }
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
        .confirmationDialog("Delete this rule?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete rule", role: .destructive) {
                if let rule, model.delete(rule) { dismiss() }
            }
            Button("Keep rule", role: .cancel) {}
        } message: {
            Text("This removes the local rule and its simulated restrictions. Other rules may still restrict its targets.")
        }
    }

    private func content(_ rule: Rule) -> some View {
        let calendar = Calendar.current
        let presentation = RuleDetailPresentation(rule: rule, date: model.currentDate, calendar: calendar)
        let schedule = RulesRowPresentation(rule: rule, date: model.currentDate, calendar: calendar)
        return VStack(alignment: .leading, spacing: 21) {
            Text(rule.name)
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            SimulationBanner()
            surface {
                VStack(alignment: .leading, spacing: 12) {
                    Text(presentation.state.rawValue)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(presentation.state.foreground)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(presentation.state.background, in: RoundedRectangle(cornerRadius: 8))
                    Text(presentation.explanation).font(.subheadline)
                    Text(presentation.nextChange)
                        .font(.footnote).foregroundStyle(Color("TodaySecondary"))
                    if presentation.state != .disabled {
                        Button {
                            if presentation.state == .paused { model.resume(rule) }
                            else { showingPause = true }
                        } label: {
                            Text(presentation.state == .paused ? "Resume now" : "Pause rule")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(presentation.state == .paused ? Color.white : Color("TodayInactiveCore"))
                                .background(presentation.state == .paused ? Color("TodayBlue") : Color("TodayInactiveSupport"), in: RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }.padding(17)
            }
            section("Schedule") {
                surface {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(schedule.days).font(.subheadline.weight(.semibold))
                        Text(schedule.timeRange).font(.subheadline)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(15)
                }
                if rule.schedule.crossesMidnight {
                    helper("Selected days are the days this schedule starts.")
                }
            }
            section("Apps · \(rule.sampleAppIDs.count)") {
                surface {
                    VStack(spacing: 0) {
                        if rule.sampleAppIDs.isEmpty { empty("No apps in this rule.") }
                        ForEach(rule.sampleAppIDs.sorted(), id: \.self) { id in
                            if id != rule.sampleAppIDs.sorted().first { Divider() }
                            NavigationLink {
                                WhyBlockedAppView(appID: id)
                            } label: {
                                targetRow(name: SimulationCatalog.name(for: id), subtitle: "View current restrictions", badge: String(SimulationCatalog.name(for: id).suffix(1)))
                            }
                            .accessibilityLabel("View current restriction explanation for \(SimulationCatalog.name(for: id))")
                        }
                    }
                }
                helper("Simulator examples, not apps installed on your phone.")
            }
            section("Websites · \(rule.websites.count)") {
                surface {
                    VStack(spacing: 0) {
                        if rule.websites.isEmpty { empty("No websites in this rule.") }
                        ForEach(rule.websites) { pattern in
                            if pattern.id != rule.websites.first?.id { Divider() }
                            let scope = pattern.scope == .exactHost ? "This website" : "All subdomains"
                            NavigationLink {
                                WebsiteLookupView(initialHost: pattern.host)
                            } label: {
                                targetRow(name: pattern.host, subtitle: "\(scope) · Check website")
                            }
                            .accessibilityLabel("Check website for \(pattern.host), \(scope)")
                        }
                    }
                }
                helper("Other rules may still restrict these targets when this rule is paused, disabled, or deleted.")
            }
            section("Rule controls") {
                surface {
                    Toggle(isOn: Binding(get: {
                        self.rule?.isEnabled ?? false
                    }, set: { value in
                        if let saved = self.rule { model.setEnabled(value, for: saved) }
                    })) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enabled").font(.subheadline.weight(.semibold))
                            helper("Turn off to stop this rule indefinitely.")
                        }
                    }
                    .accessibilityHint("Turn off to stop this rule indefinitely. Schedule, targets, and any retained pause are preserved.")
                    .padding(15).frame(minHeight: 64)
                }
            }
            surface {
                Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                    Text("Delete rule")
                        .font(.subheadline)
                        .foregroundStyle(Color("TodayErrorCore"))
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, 15)
                }.buttonStyle(.plain)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(20)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 3)
            content()
        }
    }

    private func surface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("TodayLine"), lineWidth: 1))
    }

    private func helper(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(Color("TodaySecondary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func empty(_ text: String) -> some View {
        helper(text).frame(maxWidth: .infinity, alignment: .leading).padding(15)
    }

    private func targetRow(name: String, subtitle: String, badge: String? = nil) -> some View {
        HStack(spacing: 12) {
            if let badge {
                Text(badge).font(.subheadline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color("TodaySimulationText"))
                    .background(Color("TodaySimulationBackground"), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(Color("TodayInk"))
                helper(subtitle)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption)
                .foregroundStyle(Color("TodaySecondary")).accessibilityHidden(true)
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}
