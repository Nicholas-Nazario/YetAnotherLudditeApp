import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("Prototype") {
                SimulationBanner()
                Text("This build previews rules locally. Screen Time authorization, Safari blocking, and Shortcuts setup arrive in later phases.")
                    .foregroundStyle(.secondary)
            }
            Section("Privacy") {
                Text("No account, project server, analytics, browsing history, or app usage history.")
                Text("Rules stay on this device and are excluded from app backups. A restore or reinstall will require recreating them.")
                    .foregroundStyle(.secondary)
            }
            Section("Local data") {
                LabeledContent("Saved rules", value: String(model.rules.count))
                if !model.storageReady {
                    Text("The local rule file could not be read. It has not been overwritten. Delete it here to start again.")
                        .foregroundStyle(.red)
                }
                Button("Delete all local rules", role: .destructive) {
                    showingResetConfirmation = true
                }
            }
            Section {
                Text("Yet Another Luddite App")
                Text("Open source under the MIT License")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Delete all local rules?", isPresented: $showingResetConfirmation) {
            Button("Delete all rules", role: .destructive) { model.resetLocalData() }
        } message: {
            Text("This deletes the prototype's rule file and clears simulated restrictions.")
        }
    }
}
