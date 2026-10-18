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
            if phase == .active { Task { await model.reloadLocalRules() } }
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
