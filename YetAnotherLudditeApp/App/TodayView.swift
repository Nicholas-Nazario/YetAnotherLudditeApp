import SwiftUI
import Combine

private extension TodayTone {
    var core: Color {
        switch self {
        case .active: return Color("TodayActiveCore")
        case .paused: return Color("TodayPausedCore")
        case .inactive: return Color("TodayInactiveCore")
        }
    }

    var text: Color {
        switch self {
        case .active: return Color("TodayActiveText")
        case .paused: return Color("TodayPausedText")
        case .inactive: return Color("TodayInactiveText")
        }
    }

    var support: Color {
        switch self {
        case .active: return Color("TodayActiveSupport")
        case .paused: return Color("TodayPausedSupport")
        case .inactive: return Color("TodayInactiveSupport")
        }
    }

    var gradient: [Color] {
        switch self {
        case .active:
            return [Color("TodayActiveGradientStart"), Color("TodayActiveGradientMiddle"), Color("TodayActiveGradientEnd")]
        case .paused:
            return [Color("TodayPausedGradientStart"), Color("TodayPausedGradientEnd")]
        case .inactive:
            return [Color("TodayInactiveGradientStart"), Color("TodayInactiveGradientEnd")]
        }
    }
}

struct SimulationBanner: View {
    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: "eye")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("TodaySimulationText"))
                .frame(width: 34, height: 34)
                .background(Color("TodaySimulationIcon"), in: RoundedRectangle(cornerRadius: 11))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Simulation")
                    .font(.caption.weight(.bold))
                Text("No apps or websites are actually blocked.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Color("TodaySimulationText"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Color("TodaySimulationBackground"), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("TodaySimulationBorder"), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Simulation. No apps or websites are actually blocked.")
    }
}

struct TodayView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showingEditor = false
    @State private var previewExpanded = false

    private var previewTime: Binding<Date> {
        Binding(
            get: { model.previewDate ?? model.currentDate },
            set: { model.previewDate = $0 }
        )
    }

    var body: some View {
        ScrollView {
            if let snapshot = model.snapshot {
                let state = TodayPresentation(rules: model.rules, snapshot: snapshot, at: model.currentDate)
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 20)
                    SimulationBanner()
                        .padding(.bottom, 16)
                    TodaySummaryCard(state: state)
                        .padding(.bottom, 15)
                    TodayNextCard(state: state)
                        .padding(.bottom, 15)
                    #if targetEnvironment(simulator)
                    previewCard
                        .padding(.bottom, 25)
                    #else
                    Spacer(minLength: 10)
                    #endif
                    targetsSection(state: state)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color("TodayCanvas").ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEditor) {
            NavigationStack { RuleEditorView(existingRule: nil) }
                .environmentObject(model)
        }
        .onAppear { model.refreshClock() }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            model.refreshClock()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.currentDate.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(Color("TodaySecondary"))
                Text("Today")
                    .font(.largeTitle.bold())
                    .tracking(-1.2)
                    .foregroundStyle(Color("TodayInk"))
            }
            Spacer(minLength: 8)
            Button { showingEditor = true } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("TodayBlueOnFill"))
                    .frame(width: 44, height: 44)
                    .background(Color("TodayBlue"), in: RoundedRectangle(cornerRadius: 15))
            }
            .accessibilityLabel("Add rule")
            .accessibilityHint("Opens the rule editor")
        }
    }

    #if targetEnvironment(simulator)
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { previewExpanded.toggle() } label: {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 9) {
                        previewHeader
                        Text(previewExpanded ? "Done" : "Change")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("TodayBlue"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                } else {
                    HStack(spacing: 11) {
                        previewHeader
                        Spacer(minLength: 8)
                        Text(previewExpanded ? "Done" : "Change")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("TodayBlue"))
                    }
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(model.previewDate == nil ? "Current time" : "Previewing another time"), \(model.currentDate.formatted(date: .abbreviated, time: .shortened)). \(previewExpanded ? "Close" : "Change") preview time")

            if previewExpanded {
                Divider().overlay(Color("TodayLine")).padding(.vertical, 13)
                DatePicker("See rules at another time", selection: previewTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .tint(Color("TodayBlue"))
                if model.previewDate != nil {
                    Button("Reset to now") {
                        model.previewDate = nil
                        previewExpanded = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TodayBlue"))
                    .padding(.top, 12)
                    .accessibilityHint("Returns all rule previews to the current device time")
                }
            }
        }
        .padding(14)
        .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("TodayLine"), lineWidth: 1))
    }

    private var previewHeader: some View {
        HStack(spacing: 11) {
            Image(systemName: "clock")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("TodayBlue"))
                .frame(width: 35, height: 35)
                .background(Color("TodaySimulationBackground"), in: RoundedRectangle(cornerRadius: 11))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Preview time")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TodayInk"))
                Text("\(model.previewDate == nil ? "Now" : "Previewing") · \(model.currentDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Color("TodaySecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    #endif

    private func targetsSection(state: TodayPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Text("Restricted in preview")
                    .font(.title3.weight(.semibold))
                    .tracking(-0.4)
                    .foregroundStyle(Color("TodayInk"))
                Text(String(state.targets.count))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(state.tone.core)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(state.tone.support, in: RoundedRectangle(cornerRadius: 7))
                    .accessibilityLabel("\(state.targets.count) targets")
                Spacer()
            }

            if state.targets.isEmpty {
                TodayEmptyCard(hasRules: state.hasRules) { showingEditor = true }
            } else {
                ForEach(state.targets) { target in
                    TodayTargetCard(target: target)
                }
            }
        }
    }
}

private struct TodaySummaryCard: View {
    let state: TodayPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text("YOUR BOUNDARIES")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(state.statusLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(state.tone.support.opacity(0.88), in: Capsule())
                    .overlay(Capsule().stroke(state.tone.core.opacity(0.2), lineWidth: 1))
            }
            Text(state.title)
                .font(.title.bold())
                .tracking(-0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 15)
            Text(state.detail)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)
        }
        .foregroundStyle(state.tone.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(21)
        .background(
            LinearGradient(colors: state.tone.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .shadow(color: state.tone.core.opacity(0.12), radius: 13, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.statusLabel) preview. \(state.title). \(state.detail)")
    }
}

private struct TodayNextCard: View {
    let state: TodayPresentation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.body.weight(.medium))
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.nextLabel)
                    .font(.caption2.weight(.heavy))
                    .tracking(1.1)
                    .foregroundStyle(state.tone.core)
                Text(state.nextTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TodayInk"))
                    .fixedSize(horizontal: false, vertical: true)
                Text(state.nextDetail)
                    .font(.caption)
                    .foregroundStyle(Color("TodaySecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(state.tone.core)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(state.tone.support, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.nextLabel). \(state.nextTitle). \(state.nextDetail)")
    }
}

private struct TodayTargetCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let target: TodayTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Group {
                    switch target.kind {
                    case .sampleApp:
                        Text(String(target.name.last ?? "A"))
                            .font(.title3.weight(.bold))
                    case .website:
                        Image(systemName: "globe")
                            .font(.title3.weight(.medium))
                    }
                }
                .foregroundStyle(Color("TodayActiveDeep"))
                .frame(width: 43, height: 43)
                .background(Color("TodayActiveSupport"), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(target.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("TodayInk"))
                    Text(target.typeDescription)
                        .font(.caption)
                        .foregroundStyle(Color("TodaySecondary"))
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(target.voiceOverDescription)

            Divider().overlay(Color("TodayLine")).padding(.vertical, 12)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    reasonSummary
                    inspectLink
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    reasonSummary
                    Spacer(minLength: 4)
                    inspectLink
                }
            }
        }
        .padding(14)
        .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("TodayLine"), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("TodayActiveCore"))
                .frame(width: 3)
                .padding(.vertical, 3)
                .accessibilityHidden(true)
        }
    }

    private var reasonSummary: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(target.ruleNames.count) \(target.ruleNames.count == 1 ? "rule" : "rules")")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("TodayActiveDeep"))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color("TodayActiveSupport"), in: RoundedRectangle(cornerRadius: 6))
            Text(target.ruleNames.joined(separator: " + "))
                .font(.caption)
                .foregroundStyle(Color("TodaySecondary"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inspectLink: some View {
        NavigationLink {
            switch target.kind {
            case .sampleApp(let id): WhyBlockedAppView(appID: id)
            case .website(let pattern): WebsiteLookupView(initialHost: pattern.host)
            }
        } label: {
            HStack(spacing: 3) {
                Text(target.actionTitle)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("TodayBlue"))
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(target.actionTitle): \(target.name)")
        .accessibilityHint(target.voiceOverDescription)
    }
}

private struct TodayEmptyCard: View {
    let hasRules: Bool
    let createRule: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: hasRules ? "clock" : "plus")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color("TodayInactiveCore"))
                .frame(width: 42, height: 42)
                .background(Color("TodayInactiveSupport"), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            Text(hasRules ? "Nothing active at this time" : "No rules yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("TodayInk"))
            Text(hasRules
                 ? "Your next scheduled change is shown above."
                 : "Choose a sample app or website and a schedule to create your first boundary.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("TodaySecondary"))
                .fixedSize(horizontal: false, vertical: true)
            if !hasRules {
                Button("Create rule", action: createRule)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("TodayBlue"))
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(23)
        .background(Color("TodayInactiveSupport").opacity(0.28), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color("TodayInactiveCore").opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }
}
