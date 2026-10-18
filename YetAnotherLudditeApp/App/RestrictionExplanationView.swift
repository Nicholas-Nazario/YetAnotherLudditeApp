import SwiftUI
import UIKit

struct WhyBlockedAppView: View {
    let appID: String
    var body: some View { RestrictionExplanationView(appID: appID) }
}

struct WebsiteLookupView: View {
    let initialHost: String
    var body: some View { RestrictionExplanationView(initialHost: initialHost) }
}

private struct RestrictionExplanationView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let appID: String?
    @State private var website: WebsiteCheck
    @State private var addressExpanded: Bool
    @State private var selectedPause: Rule?
    @State private var pauseOrigin: UUID?
    @FocusState private var addressFocused: Bool
    @AccessibilityFocusState private var accessibilityFocus: Focus?

    private enum Focus: Hashable {
        case result, disclosure, pause(UUID)
    }

    init(appID: String) {
        self.appID = appID
        _website = State(initialValue: WebsiteCheck(initialHost: ""))
        _addressExpanded = State(initialValue: false)
    }

    init(initialHost: String) {
        appID = nil
        _website = State(initialValue: WebsiteCheck(initialHost: initialHost))
        _addressExpanded = State(initialValue: initialHost.isEmpty)
    }

    private var target: ExplanationTarget? {
        if let appID { return .sampleApp(appID) }
        return website.checkedHost.map { .host($0) }
    }
    private var targetName: String {
        appID.map(SimulationCatalog.name(for:)) ?? website.checkedHost ?? "Check website"
    }
    private var dataAvailable: Bool {
        !model.isLoadingRules && model.storageReady && model.snapshot != nil
    }
    private var resultIdentity: String {
        guard dataAvailable, let target else { return "unavailable" }
        return targetName + model.explanation(for: target).reasons.map { $0.id.uuidString }.joined()
    }

    var body: some View {
        let explanation = target.map { model.explanation(for: $0) }
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    identity
                    VStack(alignment: .leading, spacing: 9) {
                        SimulationBanner()
                        helper(appID == nil
                            ? "The website and its www version are treated as equivalent. Other subdomains may differ."
                            : "Example identity, not an app installed on your phone.")
                    }
                    if appID == nil { addressDisclosure }
                    if model.isLoadingRules {
                        ProgressView("Loading local rule information…")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    } else if !model.storageReady || model.snapshot == nil {
                        dataError
                    } else if let explanation {
                        result(explanation).id("result")
                        if !explanation.reasons.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Responsible rules")
                                    .font(.subheadline.weight(.semibold))
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(explanation.reasons) { reason in
                                    reasonCard(reason, explanation: explanation)
                                }
                            }
                            .padding(.top, 5)
                        }
                        helper("These rules apply now. Other rules may start or end later.")
                    } else {
                        helper("Submit a website address to check its host locally.")
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(20)
            }
            .onChange(of: website.error) { error in
                if error != nil { proxy.scrollTo("address-input", anchor: .center) }
            }
            .onChange(of: addressFocused) { focused in
                if focused { proxy.scrollTo("address-input", anchor: .center) }
            }
            .onChange(of: resultIdentity) { _ in
                guard dataAvailable, selectedPause == nil, let target else { return }
                let explanation = model.explanation(for: target)
                announce("\(targetName). \(resultTitle(explanation))")
                // Typing/validation retains keyboard and field focus.
                if !addressFocused { accessibilityFocus = .result }
            }
        }
        .background(Color("TodayCanvas").ignoresSafeArea())
        .foregroundStyle(Color("TodayInk"))
        .tint(Color("TodayBlue"))
        .navigationTitle("Why blocked")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onAppear { model.refreshClock() }
        .sheet(item: $selectedPause, onDismiss: pauseDismissed) { rule in
            NavigationStack { PauseRuleView(rule: rule) }
                .environmentObject(model)
        }
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if appID == nil { Image(systemName: "globe") }
                else { Text(String(targetName.suffix(1))) }
            }
            .font(.system(size: 21, weight: .semibold))
            .frame(width: 46, height: 46)
            .foregroundStyle(Color("TodayBlue"))
            .background(Color("TodaySimulationBackground"), in: RoundedRectangle(cornerRadius: 15))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                helper(appID == nil ? (website.checkedHost == nil ? "Website" : "Checked host") : "Sample app")
                Text(targetName).font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }

    private var addressDisclosure: some View {
        surface {
            DisclosureGroup(isExpanded: $addressExpanded) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Website address").font(.subheadline.weight(.semibold))
                    TextField("m.youtube.com", text: $website.input)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.search)
                        .onSubmit(checkHost)
                        .focused($addressFocused)
                        .accessibilityLabel("Website address")
                        .accessibilityHint(website.error ?? "Enter a domain or URL. Only the host is checked locally.")
                        .padding(10)
                        .frame(minHeight: 44)
                        .background(Color("TodayCanvas"), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("TodayLine")))
                        .id("address-input")
                    helper("Enter a domain or URL. Only the host is checked locally.")
                    if let error = website.error {
                        Text(error).font(.caption).foregroundStyle(Color("TodayErrorCore"))
                    }
                    Button("Check host", action: checkHost)
                        .buttonStyle(ExplanationPrimaryButton())
                        .disabled(model.isLoadingRules)
                }
                .padding(.bottom, 14)
            } label: {
                Text("Check another address")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color("TodayBlue"))
                    .frame(minHeight: 44)
                    .accessibilityFocused($accessibilityFocus, equals: .disclosure)
            }
            .padding(.horizontal, 14)
            .onChange(of: addressExpanded) { expanded in
                if !expanded {
                    addressFocused = false
                    accessibilityFocus = .disclosure
                }
            }
        }
    }

    private func result(_ explanation: RestrictionExplanation) -> some View {
        let active = !explanation.reasons.isEmpty
        let formatter = DateFormatter()
        formatter.calendar = explanation.calendar
        formatter.timeZone = explanation.calendar.timeZone
        formatter.timeStyle = .short
        return VStack(alignment: .leading, spacing: 9) {
            Text("Simulated state · \(formatter.string(from: explanation.date))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(active ? "TodayActiveDeep" : "TodayInactiveCore"))
            Text(resultTitle(explanation)).font(.title2.weight(.bold))
            Text(active
                ? "This target remains restricted while any listed rule applies. Pausing one rule may leave others in effect."
                : "No active rule restricts this target now. Paused, disabled, and rules outside their scheduled hours do not apply.")
                .font(.footnote)
                .foregroundStyle(Color(active ? "TodayActiveDeep" : "TodayInactiveCore"))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(17)
        .background(Color(active ? "TodayActiveSupport" : "TodayInactiveSupport"), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("TodayLine")))
        .accessibilityElement(children: .combine)
        .accessibilityFocused($accessibilityFocus, equals: .result)
    }

    private func reasonCard(_ reason: RestrictionReason, explanation: RestrictionExplanation) -> some View {
        let presentation = ExplanationReasonPresentation(reason: reason, date: explanation.date, calendar: explanation.calendar)
        return surface {
            VStack(spacing: 0) {
                NavigationLink {
                    RuleDetailView(ruleID: reason.id)
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(reason.rule.name).font(.headline)
                                .foregroundStyle(Color("TodayInk"))
                            helper(presentation.schedule)
                            Text(presentation.windowEnd).font(.caption.weight(.semibold))
                                .foregroundStyle(Color("TodayActiveDeep"))
                            ForEach(presentation.matchingExplanations, id: \.self) { helper($0) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right").font(.caption)
                            .foregroundStyle(Color("TodaySecondary")).accessibilityHidden(true)
                    }
                    .padding(15).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Open Rule details")
                Divider()
                ViewThatFits(in: .horizontal) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        HStack {
                            appliesNow
                            Spacer(minLength: 8)
                            pauseButton(reason.rule)
                        }
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        appliesNow.padding(.top, 10)
                        pauseButton(reason.rule)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.horizontal, 15)
            }
        }
    }

    private var appliesNow: some View {
        Text("Applies now").font(.caption2).foregroundStyle(Color("TodayActiveDeep"))
    }

    private func pauseButton(_ rule: Rule) -> some View {
        Button {
            model.refreshClock()
            guard rule.isEffective(at: model.currentDate, calendar: model.calendar) else { return }
            pauseOrigin = rule.id
            selectedPause = rule
        } label: {
            Text("Pause…").font(.footnote.weight(.semibold))
                .foregroundStyle(Color("TodayBlue"))
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pause \(rule.name)")
        .accessibilityHint("Review duration and effects before confirming")
        .accessibilityFocused($accessibilityFocus, equals: .pause(rule.id))
    }

    private var dataError: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rule information unavailable").font(.headline)
            Text(model.localDataError ?? "This target’s current state cannot be determined.").font(.footnote)
            Button("Try again") {
                Task {
                    await model.reloadLocalRules()
                    if let error = model.localDataError { announce(error) }
                }
            }.buttonStyle(ExplanationPrimaryButton())
        }
        .foregroundStyle(Color("TodayErrorCore"))
        .frame(maxWidth: .infinity, alignment: .leading).padding(17)
        .background(Color("TodayErrorSupport"), in: RoundedRectangle(cornerRadius: 18))
    }

    private func resultTitle(_ explanation: RestrictionExplanation) -> String {
        let count = explanation.reasons.count
        return count == 0 ? "No active restriction" : "Restricted by \(count) \(count == 1 ? "rule" : "rules")"
    }

    private func checkHost() {
        let previousHost = website.checkedHost
        if website.submit() {
            model.refreshClock()
            addressFocused = false
            if dataAvailable {
                accessibilityFocus = .result
                // Changed-host results are announced once by resultIdentity.
                if previousHost == website.checkedHost, let target {
                    announce("Checked host \(targetName). \(resultTitle(model.explanation(for: target)))")
                }
            } else {
                announce("Checked host \(targetName). Rule information is unavailable; its current state cannot be determined.")
            }
        } else {
            addressFocused = true
            if let error = website.error { announce(error) }
        }
    }

    private func pauseDismissed() {
        model.refreshClock()
        if let target, let origin = pauseOrigin,
           model.explanation(for: target).reasons.contains(where: { $0.id == origin }) {
            accessibilityFocus = .pause(origin)
        } else { accessibilityFocus = .result }
        pauseOrigin = nil
    }

    private func helper(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(Color("TodaySecondary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func surface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("TodayLine")))
    }

    private func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}

private struct ExplanationPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.footnote.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(minWidth: 44, minHeight: 44)
            .background(Color("TodayBlue").opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 10))
    }
}
