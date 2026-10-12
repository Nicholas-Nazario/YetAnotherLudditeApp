import SwiftUI

struct PauseRuleView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let rule: Rule
    @State private var minutesText = "15"

    private let presets = [15, 30, 60, 120, 240, 480, 1_440]

    private var minutes: Int? {
        guard let value = Int(minutesText), (15...1_440).contains(value) else { return nil }
        return value
    }

    var body: some View {
        Form {
            Section {
                SimulationBanner()
                Text("Pause \(rule.name)").font(.headline)
                Text("A pause suspends this rule only. Other active rules still apply.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Duration") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(presets, id: \.self) { value in
                            Button(durationLabel(value)) { minutesText = String(value) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                TextField("Minutes (15–1440)", text: $minutesText)
                    .keyboardType(.numberPad)
                if let minutes {
                    LabeledContent("Expected return", value: model.currentDate.addingTimeInterval(TimeInterval(minutes * 60))
                        .formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text("Choose 15 minutes through 24 hours.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            Section("What remains blocked now") {
                if rule.sampleAppIDs.isEmpty && rule.websites.isEmpty {
                    Text("This rule has no targets.")
                }
                ForEach(rule.sampleAppIDs.sorted(), id: \.self) { id in
                    let others = model.otherBlockingRules(forSampleApp: id, excluding: rule)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(SimulationCatalog.name(for: id))
                        Text(others.isEmpty
                             ? "No other active rule blocks this sample app."
                             : "Still blocked by \(others.map(\.name).joined(separator: ", ")).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(rule.websites) { pattern in
                    let others = model.otherBlockingRules(forHost: pattern.host, excluding: rule)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pattern.label)
                        Text(others.isEmpty
                             ? "No other active rule blocks \(pattern.host)."
                             : "\(pattern.host) remains blocked by \(others.map(\.name).joined(separator: ", ")).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !rule.websites.isEmpty {
                    Text("Website overlap is shown for each listed base host. Subdomains may have different matching rules.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Pause Rule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Pause") {
                    if let minutes {
                        if model.pause(rule, minutes: minutes) {
                            dismiss()
                        }
                    }
                }
                .disabled(minutes == nil)
            }
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }
}
