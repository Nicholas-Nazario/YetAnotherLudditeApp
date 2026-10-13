import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "clock") }

            NavigationStack {
                RulesView()
            }
            .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.refreshClock() }
        }
        .task(id: model.rules.map(\.pauseUntil) + [model.snapshot?.nextRuleChange]) {
            while !Task.isCancelled {
                model.refreshClock()
                let now = model.currentDate
                let nextMinute = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 60) + 1) * 60)
                let nextPause = model.rules.compactMap(\.pauseUntil).filter { $0 > now }.min()
                let wake = min(nextMinute, model.snapshot?.nextRuleChange ?? nextMinute, nextPause ?? nextMinute)
                do {
                    try await Task.sleep(nanoseconds: UInt64(max(0.01, wake.timeIntervalSinceNow) * 1_000_000_000))
                } catch { return }
            }
        }
        .alert("Local rules", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct WhyBlockedAppView: View {
    @EnvironmentObject private var model: AppModel
    let appID: String

    var body: some View {
        List {
            Section {
                SimulationBanner()
                Text(SimulationCatalog.name(for: appID)).font(.headline)
            }
            Section("Responsible rules") {
                let matching = model.blockingRules(forSampleApp: appID)
                if matching.isEmpty {
                    Text("No active rule blocks this sample app right now.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(matching) { rule in
                        NavigationLink(rule.name) {
                            RuleDetailView(ruleID: rule.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Why blocked")
    }
}

struct WebsiteLookupView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query: String
    @State private var inspectedHost: String?
    @State private var inputError: String?

    init(initialHost: String) {
        _query = State(initialValue: initialHost)
        _inspectedHost = State(initialValue: initialHost.isEmpty ? nil : initialHost)
    }

    var body: some View {
        List {
            Section {
                SimulationBanner()
            }
            Section("Website host") {
                TextField("m.youtube.com", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button("Check host") { inspect() }
                if let inputError {
                    Text(inputError).foregroundStyle(.red)
                }
            }
            if let inspectedHost {
                Section("Rules matching \(inspectedHost)") {
                    let matching = model.blockingRules(forHost: inspectedHost)
                    if matching.isEmpty {
                        Text("No active rule blocks this host right now.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matching) { rule in
                            NavigationLink(rule.name) {
                                RuleDetailView(ruleID: rule.id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Why blocked")
    }

    private func inspect() {
        do {
            inspectedHost = try DomainPattern.parse(query, scope: .exactHost).host
            inputError = nil
        } catch {
            inspectedHost = nil
            inputError = error.localizedDescription
        }
    }
}
