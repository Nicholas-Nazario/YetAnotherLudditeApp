import SwiftUI
import UIKit

struct PauseRuleView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    let rule: Rule
    @State private var selection = 15
    @State private var hours = 0
    @State private var minutePart = 15
    @State private var expanded = false
    @State private var saveError: String?
    @AccessibilityFocusState private var disclosureFocused: Bool

    private var savedRule: Rule? { model.rules.first { $0.id == rule.id } }
    private var minutes: Int { selection == 0 ? hours * 60 + minutePart : selection }
    private var valid: Bool { PauseReview.isValidDuration(minutes) }
    private var unavailable: String? {
        if !model.storageReady || model.snapshot == nil {
            return "Local rule information is unavailable. Return to Rule details and try again after resolving the local storage error."
        }
        return PauseReview.unavailableReason(for: savedRule, at: model.currentDate)
    }
    private var review: PauseReview {
        PauseReview(rule: savedRule ?? rule, rules: model.rules, date: model.currentDate, calendar: .current)
    }
    private var durationError: String {
        hours == 24 && minutePart > 0
            ? "For 24 hours, choose 0 minutes."
            : "Choose at least 15 minutes and no more than 24 hours."
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(savedRule?.name ?? rule.name)
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                        SimulationBanner()
                        helper("Only this rule will pause. Other rules still apply.")
                    }
                    if let unavailable {
                        errorBanner(unavailable)
                    } else {
                        durationSection
                        timingSection
                        effectSection
                    }
                    if let saveError {
                        errorBanner(saveError + " Your selection is retained. Try again or Cancel.")
                            .id("save-error")
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(20)
            }
            .onChange(of: saveError) { error in
                if let error {
                    proxy.scrollTo("save-error", anchor: .bottom)
                    announce(error)
                }
            }
        }
        .background(Color("TodayCanvas").ignoresSafeArea())
        .foregroundStyle(Color("TodayInk"))
        .tint(Color("TodayBlue"))
        .navigationTitle("Pause rule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color("TodayBlue"))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                model.refreshClock()
                guard valid, unavailable == nil else { return }
                if model.pause(rule, minutes: minutes) { dismiss() }
                else {
                    saveError = model.errorMessage ?? "Could not save the pause."
                    model.errorMessage = nil
                }
            } label: {
                Text("Confirm pause")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(Color("TodayInactiveCore"))
                    .background(Color("TodayInactiveSupport"), in: RoundedRectangle(cornerRadius: 12))
                    .opacity(valid && unavailable == nil ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!valid || unavailable != nil)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(Color("TodayCard").ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Divider() }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
        .onAppear { model.refreshClock() }
        .onChange(of: scenePhase) { if $0 == .active { model.refreshClock() } }
        .onChange(of: minutes) { _ in
            model.refreshClock()
            announce(valid ? "Pause ends \(review.formatted(model.currentDate.addingTimeInterval(TimeInterval(minutes * 60))))." : durationError)
        }
        .onChange(of: unavailable) { if let message = $0 { announce(message) } }
    }

    private var durationSection: some View {
        section("Duration") {
            ViewThatFits(in: .horizontal) {
                if !dynamicTypeSize.isAccessibilitySize {
                    presetGrid(columns: 4)
                }
                presetGrid(columns: 2)
                presetGrid(columns: 1)
            }
            if selection == 0 {
                surface {
                    Group {
                        if !dynamicTypeSize.isAccessibilitySize {
                            HStack(spacing: 14) {
                                wheel("Hours", value: $hours, range: 0...24)
                                wheel("Minutes", value: $minutePart, range: 0...59)
                            }
                        } else {
                            VStack(spacing: 14) {
                                wheel("Hours", value: $hours, range: 0...24)
                                wheel("Minutes", value: $minutePart, range: 0...59)
                            }
                        }
                    }.padding(12)
                }
                helper("15 minutes through 24 hours.")
                if !valid {
                    Text(durationError).font(.caption)
                        .foregroundStyle(Color("TodayErrorCore"))
                }
            }
        }
    }

    private func presetGrid(columns: Int) -> some View {
        // Intrinsic label widths select the first layout that fits at this text size.
        Grid(horizontalSpacing: 7, verticalSpacing: 7) {
            ForEach(0..<(4 / columns), id: \.self) { row in
                GridRow {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        let values = [15, 30, 60, 0]
                        Button { selection = values[index] } label: {
                            Text(["15 min", "30 min", "1 hour", "Custom"][index])
                                .font(.footnote.weight(selection == values[index] ? .semibold : .regular))
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selection == values[index] ? Color("TodayInactiveSupport") : Color("TodayCard"), in: RoundedRectangle(cornerRadius: 11))
                                .overlay(RoundedRectangle(cornerRadius: 11).stroke(selection == values[index] ? Color("TodayInactiveCore") : Color("TodayLine"), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == values[index] ? .isSelected : [])
                    }
                }
            }
        }
    }

    private func wheel(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 0) {
            Text(label).font(.subheadline.weight(.semibold))
            Picker(label, selection: value) {
                ForEach(range, id: \.self) { Text(String($0)).tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 160)
            .clipped()
            .accessibilityLabel(label)
            .accessibilityHint("15 minutes through 24 hours. \(valid ? "" : durationError)")
        }
    }

    private var timingSection: some View {
        surface {
            VStack(alignment: .leading, spacing: 5) {
                helper("Pause ends")
                Text(valid ? review.formatted(model.currentDate.addingTimeInterval(TimeInterval(minutes * 60))) : "Choose a valid duration")
                    .font(.headline)
                helper(valid ? review.scheduleConsequence(minutes: minutes) : "Your chosen duration must be valid before confirming.")
            }.padding(15)
        }
    }

    private var effectSection: some View {
        let review = review
        return section("Effect of this pause") {
            surface {
                VStack(alignment: .leading, spacing: 12) {
                    if !review.changesNow {
                        Text("Nothing changes now. This rule is outside its scheduled hours.")
                    } else {
                        if review.releasedAppCount > 0 {
                            Text("\(review.releasedAppCount) \(review.releasedAppCount == 1 ? "app" : "apps") would no longer be restricted.")
                        }
                        if review.retainedAppCount > 0 {
                            Text("\(review.retainedAppCount) \(review.retainedAppCount == 1 ? "app" : "apps") would remain restricted by other rules.")
                        }
                    }
                    if !review.rule.websites.isEmpty { Text("Website effects vary by address.") }
                    Divider()
                    DisclosureGroup(isExpanded: $expanded) {
                        targetDetails(review)
                    } label: {
                        Text(expanded ? "Hide affected targets" : "View affected targets")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color("TodayBlue"))
                            .frame(minHeight: 44)
                            .accessibilityFocused($disclosureFocused)
                    }
                    .onChange(of: expanded) { if !$0 { disclosureFocused = true } }
                }
                .font(.subheadline)
                .padding(15)
            }
            helper("This describes what changes now. Other rules may start or end during the pause.")
        }
    }

    private func targetDetails(_ review: PauseReview) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            ForEach(review.rule.sampleAppIDs.sorted(), id: \.self) { id in
                let reasons = review.appReasons(id)
                VStack(alignment: .leading, spacing: 5) {
                    Divider()
                    Text(SimulationCatalog.name(for: id)).font(.subheadline.weight(.semibold))
                    helper(outcome(reasons, review: review))
                }
            }
            if !review.rule.sampleAppIDs.isEmpty {
                helper("Sample identities, not apps installed on your phone.")
            }
            ForEach(review.rule.websites) { pattern in
                VStack(alignment: .leading, spacing: 9) {
                    Divider()
                    Text("\(pattern.host) · \(pattern.scope == .exactHost ? "This website" : "All subdomains")")
                        .font(.subheadline.weight(.semibold))
                    ForEach(review.exampleHostGroups(for: pattern), id: \.self) { hosts in
                        let host = hosts[0]
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hosts.count == 2 ? "\(host) + www" : host)
                                .font(.footnote.weight(.semibold))
                                .accessibilityLabel(hosts.joined(separator: " and "))
                            helper(outcome(review.hostReasons(host), review: review, host: host))
                        }
                    }
                    helper("Other addresses may differ.")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func outcome(_ reasons: [Rule], review: PauseReview, host: String? = nil) -> String {
        if !reasons.isEmpty {
            return "Still restricted · " + reasons.map { review.responsibility($0, host: host) }.joined(separator: "; ")
        }
        return review.changesNow ? "Would be unrestricted" : "Unrestricted now. This pause makes no immediate change."
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func surface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("TodayCard"), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("TodayLine"), lineWidth: 1))
    }

    private func helper(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(Color("TodaySecondary"))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorBanner(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(Color("TodayErrorCore"))
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(Color("TodayErrorSupport"), in: RoundedRectangle(cornerRadius: 13))
    }

    private func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
