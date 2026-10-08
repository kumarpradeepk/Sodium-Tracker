//
//  LogSheets.swift
//  Sodium Tracker
//
//  The logging stack: the salt-shelf sheet (search + browse + actions), the
//  portion sheet, quick log, and create food.
//

import SwiftUI
import SwiftData
import os

// MARK: - Log a food (z40)

struct LogSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions

    @Query(sort: \CustomFood.createdAt) private var customFoods: [CustomFood]
    @Query private var favorites: [Favorite]
    @Query private var entries: [LogEntry]

    @FocusState private var searchFocused: Bool

    // FatSecret live search
    @State private var remoteResults: [RemoteFood] = []
    @State private var remoteSearching = false
    @State private var remoteError: String?
    @State private var searchRetry = 0
    @State private var loadingRemoteID: String?

    private var query: String {
        ui.search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(topInset: 76, onClose: { ui.closeFoodLog() }) {
            VStack(spacing: 0) {
                HStack {
                    PinchText("Log a food")
                        .font(PinchFonts.display(21, .bold))
                        .foregroundStyle(p.ink)
                    Spacer()
                    SheetCloseButton { ui.closeFoodLog() }
                        .accessibilityIdentifier("food-log.close")
                }
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 0, trailing: 20))

                searchField
                    .padding(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if query.isEmpty {
                            actionGrid
                                .padding(.top, 12)
                        }
                        remoteSection
                        resultSections
                    }
                    .padding(EdgeInsets(top: 6, leading: 20, bottom: 40, trailing: 20))
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if ui.picked == nil && !ui.qlOpen && !ui.cfOpen {
                    searchFocused = true
                }
            }
        }
        .onChange(of: ui.picked?.id) { _, selectedID in
            if selectedID != nil { searchFocused = false }
        }
        .task(id: "\(query)|\(searchRetry)") {
            await runRemoteSearch()
        }
    }

    /// A cancelled lookup must never overwrite a newer query's state.
    private func runRemoteSearch() async {
        _ = FatSecretConfig.logConfigurationOnce
        let requestedQuery = query
        remoteResults = []
        remoteError = nil
        remoteSearching = false
        guard requestedQuery.count >= 2 else { return }
        guard FatSecretConfig.isEnabled else {
            remoteError = "Online food search is unavailable. Your saved foods are still available."
            return
        }
        remoteSearching = true
        defer {
            if !Task.isCancelled && query == requestedQuery { remoteSearching = false }
        }
        do {
            try await Task.sleep(for: .milliseconds(350))
            let hits = try await FatSecretService.shared.search(requestedQuery)
            guard !Task.isCancelled && query == requestedQuery else { return }
            remoteResults = hits
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled && query == requestedQuery else { return }
            remoteError = "Couldn’t reach food search. Check your connection and try again."
            remoteResults = []
        }
    }

    private var searchField: some View {
        @Bindable var ui = ui
        return HStack(spacing: 9) {
            SVGShape("M9 3.2 A5.8 5.8 0 1 0 9 14.8 A5.8 5.8 0 1 0 9 3.2 M13.5 13.5 L17 17")
                .stroke(p.ink3, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 17, height: 17)

            TextField("", text: $ui.search, prompt: PinchText("Search the salt shelf…").foregroundStyle(p.ink.opacity(0.38)))
                .accessibilityIdentifier("food-log.search")
                .pinchBody(15)
                .foregroundStyle(p.ink)
                .focused($searchFocused)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    ui.search = ""
                } label: {
                    PinchText("Clear")
                        .pinchBody(12, .bold)
                        .foregroundStyle(p.ink3)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.sunk))
    }

    // MARK: Actions grid

    private var actionGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
        return VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                actionButton(
                    lines: "Quick\nlog",
                    icon: "M11.5 2.5 L4 11.5 H9 L8.5 17.5 L16 8.5 H11 Z",
                    stroke: 1.7
                ) {
                    ui.openQuickLog()
                }
                actionButton(
                    lines: "New\nfood",
                    icon: "M6.5 7.5 H13.5 V15.5 C13.5 16.6 12.6 17.5 11.5 17.5 H8.5 C7.4 17.5 6.5 16.6 6.5 15.5 Z M7.5 7.5 V5.5 H12.5 V7.5 M10 10.5 V14.5 M8 12.5 H12",
                    stroke: 1.6
                ) {
                    if canAddCustomFood {
                        ui.openCreateFood()
                    } else {
                        ui.payOpen = true
                    }
                }
            }

            if !subscriptions.isPremium {
                PinchText(PinchLocalization.format("{0} of {1} free shelf spots left. Pinch Plus is unlimited.", [String(describing: max(0, PremiumAccessPolicy.freeCustomFoodLimit - customFoods.count)), String(describing: PremiumAccessPolicy.freeCustomFoodLimit)]))
                    .pinchBody(10.5, .semibold)
                    .foregroundStyle(p.ink3)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var canAddCustomFood: Bool {
        PremiumAccessPolicy.allows(
            .unlimitedCustomFoods,
            isPremium: subscriptions.isPremium,
            customFoodCount: customFoods.count
        )
    }

    private func actionButton(lines: String, icon: String, stroke: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                LineIcon(d: icon, size: 20, stroke: stroke, color: p.brand)
                PinchText(lines)
                    .pinchBody(10, .bold)
                    .foregroundStyle(p.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 12, leading: 4, bottom: 10, trailing: 4))
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(p.line, lineWidth: 1)
            )
        }
        .buttonStyle(.pressScale)
        .accessibilityIdentifier(lines == "Quick\nlog" ? "food-log.quick-log" : "food-log.new-food")
    }

    // MARK: Sections

    private struct Section {
        let label: String
        let rows: [FoodItem]
    }

    private var sections: [Section] {
        if !query.isEmpty {
            let hits = DayEngine.search(query, builtIn: FoodItem.catalog, custom: customFoods)
            guard !hits.isEmpty else { return [] }
            return [Section(label: "SAVED & BUILT-IN", rows: hits)]
        }
        var result: [Section] = []
        result.append(Section(label: "RECOMMENDED", rows: FoodRecommendations.foods(
            entries: entries, favorites: favorites, customFoods: customFoods
        )))
        if !customFoods.isEmpty {
            result.append(Section(label: "YOUR SHELF", rows: customFoods.map(\.asFoodItem)))
        }
        let favs = favorites.compactMap { fav -> FoodItem? in
            FoodItem.builtIn(fav.foodID) ?? customFoods.first { $0.id == fav.foodID }?.asFoodItem
        }
        if !favs.isEmpty {
            result.append(Section(label: "FAVORITES", rows: favs))
        }
        for band in DayEngine.shelfBands(FoodItem.catalog) {
            result.append(Section(label: band.label, rows: band.rows))
        }
        return result
    }

    @ViewBuilder private var resultSections: some View {
        let sections = self.sections
        if query.count >= 2 && sections.isEmpty && remoteResults.isEmpty && !remoteSearching && remoteError == nil {
            noResults
        } else {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                PinchText(section.label)
                    .pinchBody(11, .bold, tracking: 0.13)
                    .foregroundStyle(p.ink3)
                    .padding(EdgeInsets(top: 16, leading: 2, bottom: 8, trailing: 2))

                PinchCard {
                    VStack(spacing: 0) {
                        ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, food in
                            foodRow(food, first: index == 0)
                        }
                    }
                }
            }
        }
    }

    private func foodRow(_ food: FoodItem, first: Bool) -> some View {
        Button {
            ui.pick(food)
        } label: {
            HStack(spacing: 11) {
                FoodIconTile(category: food.category)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: food.displayName)
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                    Text(verbatim: food.displayServing)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    PinchText(PinchFormat.mg(food.mg))
                        .pinchBody(15, .bold)
                        .monospacedDigit()
                        .foregroundStyle(p.tone(food.mg))
                    PinchText("MG")
                        .pinchBody(9.5, .bold, tracking: 0.08)
                        .foregroundStyle(p.ink3)
                }
            }
            .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("food-log.item-\(food.id)")
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    // MARK: FatSecret results

    @ViewBuilder private var remoteSection: some View {
        if let remoteError {
            VStack(alignment: .leading, spacing: 10) {
                PinchText(remoteError).pinchBody(13).foregroundStyle(p.ink2)
                Button { searchRetry += 1 } label: {
                    PinchText("Try again").pinchBody(13, .bold).foregroundStyle(p.brand)
                }
            }
            .padding(.vertical, 16)
        }
        if !query.isEmpty, query.count >= 2, FatSecretConfig.isEnabled,
           remoteSearching || !remoteResults.isEmpty {
            PinchText("FROM FATSECRET")
                .pinchBody(11, .bold, tracking: 0.13)
                .foregroundStyle(p.ink3)
                .padding(EdgeInsets(top: 16, leading: 2, bottom: 8, trailing: 2))

            PinchCard {
                VStack(spacing: 0) {
                    if remoteResults.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            PinchText("Searching the big shelf…")
                                .pinchBody(12.5)
                                .foregroundStyle(p.ink3)
                        }
                        .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
                    } else {
                        ForEach(Array(remoteResults.enumerated()), id: \.element.id) { index, food in
                            remoteRow(food, first: index == 0)
                        }
                    }
                }
            }

            PinchText("Powered by FatSecret")
                .pinchBody(9.5, .bold, tracking: 0.08)
                .foregroundStyle(p.ink3)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    private func remoteRow(_ food: RemoteFood, first: Bool) -> some View {
        Button {
            pickRemote(food)
        } label: {
            HStack(spacing: 11) {
                FoodIconTile(category: .meal)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: food.displayName)
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                    PinchText(food.subtitle)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if loadingRemoteID == food.id {
                    ProgressView()
                        .controlSize(.small)
                } else if !subscriptions.isPremium {
                    PinchText("PLUS")
                        .pinchBody(10, .bold, tracking: 0.08)
                        .foregroundStyle(p.brand)
                } else {
                    SVGShape("M1 1 L7 7 L1 13", viewBox: CGSize(width: 8, height: 14))
                        .stroke(p.ink3, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 6, height: 10)
                }
            }
            .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(loadingRemoteID != nil)
        .accessibilityIdentifier("fatsecret-food-\(food.id)")
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    /// Fetches the food's sodium, then opens the portion sheet exactly like a
    /// local pick. Foods without sodium data fall back to Quick log.
    private func pickRemote(_ food: RemoteFood) {
        guard PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: subscriptions.isPremium) else {
            ui.payOpen = true
            return
        }
        guard loadingRemoteID == nil else { return }
        loadingRemoteID = food.id
        Task {
            defer { loadingRemoteID = nil }
            do {
                let detail = try await FatSecretService.shared.details(id: food.id)
                guard ui.logOpen, !Task.isCancelled else { return }
                ui.pick(FoodItem(
                    id: FatSecretConfig.idPrefix + food.id,
                    name: detail.name,
                    serving: detail.serving,
                    mg: detail.sodiumMg,
                    category: .custom
                ))
            } catch FatSecretError.noSodium {
                guard ui.logOpen else { return }
                ui.openQuickLog(prefillName: food.name)
                ui.showToast("Sodium unavailable", "Enter the sodium from the food label.")
            } catch {
                guard ui.logOpen else { return }
                ui.showToast("Couldn’t load this food", "Check your connection and try again.")
            }
        }
    }

    private var noResults: some View {
        VStack(spacing: 0) {
            PinchText("Nothing salty by that name")
                .pinchBody(14.5, .semibold)
                .foregroundStyle(p.ink2)
            PinchText("Try \"soup,\" \"pizza,\" or \"ramen\" — or use Quick log to enter the milligrams yourself.")
                .pinchBody(12.5)
                .foregroundStyle(p.ink3)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
            Button {
                ui.openQuickLog(prefillName: query)
            } label: {
                PinchText("Quick log instead")
                    .pinchBody(12.5, .bold)
                    .foregroundStyle(p.brand)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(p.brandSoft))
            }
            .buttonStyle(.pressScale)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 36, leading: 20, bottom: 20, trailing: 20))
    }
}

// MARK: - Quick add (z40)

/// The same favorites and frequently logged foods shown on Today and the shelf.
struct QuickAddSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions
    @Query private var entries: [LogEntry]
    @Query private var favorites: [Favorite]
    @Query private var customFoods: [CustomFood]

    private var options: [FoodItem] {
        FoodRecommendations.foods(entries: entries, favorites: favorites, customFoods: customFoods)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    PinchText("QUICK ADD")
                        .pinchBody(12, .heavy, tracking: 0.10)
                        .foregroundStyle(p.ink)
                    PinchText(entries.isEmpty && favorites.isEmpty ? "Suggestions from the food catalog" : "Favorites & most logged")
                        .pinchBody(13, .medium)
                        .foregroundStyle(p.ink2)
                }
                .padding(.bottom, 12)

                ForEach(options) { option in
                    optionButton(option)
                    if option.id != options.last?.id {
                        Rectangle()
                            .fill(p.line)
                            .frame(height: 1)
                            .padding(.leading, 44)
                    }
                }

                Button {
                    openFullLog()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                        PinchText("Log a food")
                            .pinchBody(16, .heavy)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(p.onBrand)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.brand))
                }
                .buttonStyle(.pressScale(0.98))
                .accessibilityLabel(PinchLocalization.resolve("Open full food log"))
                .accessibilityIdentifier("quick-add.full-log")
                .padding(.top, 16)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(p.card))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(p.line, lineWidth: 1))
            .shadow(color: p.shadowTint.opacity(p.isDark ? 0.30 : 0.14), radius: 24, y: 10)
            .padding(.horizontal, 20)
            // Dock is 80 pt tall with a 10 pt bottom inset; leave 16 pt clear.
            .padding(.bottom, 106)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(
            .asymmetric(
                insertion: .opacity
                    .combined(with: .scale(scale: 0.90, anchor: .bottom))
                    .combined(with: .offset(y: 16)),
                removal: .opacity
                    .combined(with: .scale(scale: 0.94, anchor: .bottom))
                    .combined(with: .offset(y: 10))
            )
        )
    }

    private func optionButton(_ option: FoodItem) -> some View {
        Button {
            add(option)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: favorites.contains(where: { $0.foodID == option.id }) ? "heart.fill" : "clock.arrow.circlepath")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(p.brand)
                    .frame(width: 32, height: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: option.displayName)
                    .pinchBody(16, .bold)
                    .foregroundStyle(p.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: option.displayServing)
                    .pinchBody(11)
                    .foregroundStyle(p.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                PinchText(PinchLocalization.format("+{0} mg", [String(describing: PinchFormat.mg(option.mg))]))
                    .pinchBody(15, .bold)
                    .monospacedDigit()
                    .foregroundStyle(p.brand)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale(0.98))
        .accessibilityLabel(PinchLocalization.format("{0}, {1}, +{2} mg", [option.displayName, option.displayServing, String(describing: PinchFormat.mg(option.mg))]))
        .accessibilityIdentifier("quick-recommendation-\(option.id)")
        .accessibilityValue(PinchLocalization.resolve(favorites.contains(where: { $0.foodID == option.id }) ? "Favorite" : "Recommended"))
        .disabled(ui.quickAddRequest != nil)
    }

    private func add(_ option: FoodItem) {
        guard ui.quickAddRequest == nil else { return }
        if option.id.hasPrefix(FatSecretConfig.idPrefix), !subscriptions.isPremium {
            ui.payOpen = true
            return
        }
        withAnimation(.pinchMenu) { ui.quickAddOpen = false }
        ui.selectTab(.today)
        ui.quickAddRequest = QuickAddRequest(food: option, loggedAt: timestamp(for: ui.selectedDay()))
    }

    private func openFullLog() {
        withAnimation(.pinchSheet) {
            ui.openFoodLog()
        }
    }
}

// MARK: - Portion sheet (z50)

struct PortionSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionStore.self) private var subscriptions

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query private var favorites: [Favorite]
    @Query private var customFoods: [CustomFood]

    private var goal: Int {
        (GoalChoice(rawValue: goalChoiceRaw) ?? .fda).milligrams(custom: customGoal)
    }

    private var totalMg: Int {
        guard let food = ui.picked else { return 0 }
        return Int((Double(food.mg) * ui.servings).rounded())
    }

    private var isFavorite: Bool {
        guard let food = ui.picked else { return false }
        return favorites.contains { $0.foodID == food.id }
    }

    var body: some View {
        PinchSheet(onClose: { ui.picked = nil }) {
            if let food = ui.picked {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: food.displayName)
                                .font(PinchFonts.display(22, .bold))
                                .foregroundStyle(p.ink)
                            PinchText(PinchLocalization.format("Per {0}, {1} mg sodium", [food.displayServing, String(describing: PinchFormat.mg(food.mg))]))
                                .pinchBody(12.5)
                                .foregroundStyle(p.ink3)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            favButton(food)
                            SheetCloseButton { ui.picked = nil }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if FoodItem.builtIn(food.id) != nil {
                        PinchText("Built-in estimate. Check the label for your brand and portion.")
                            .pinchBody(11.5)
                            .foregroundStyle(p.ink3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                    }

                    stepper(food)
                        .padding(.top, 18)
                        .padding(.bottom, 6)

                    VStack(spacing: 2) {
                        PinchText(PinchLocalization.format("{0} mg", [String(describing: PinchFormat.mg(totalMg))]))
                            .font(PinchFonts.display(19, .bold))
                            .foregroundStyle(p.tone(totalMg))
                        PinchText(PinchLocalization.format("{0}% of daily budget", [String(describing: goal > 0 ? Int((Double(totalMg) / Double(goal) * 100).rounded()) : 0)]))
                            .font(PinchFonts.body(12))
                            .foregroundStyle(p.ink3)
                    }
                        .monospacedDigit()
                        .padding(.bottom, 18)

                    mealPicker
                    PinchCTA(
                        title: food.id.hasPrefix(FatSecretConfig.idPrefix) && !subscriptions.isPremium
                            ? "Unlock FatSecret logging"
                            : PinchLocalization.format("Add {0} mg", [String(describing: PinchFormat.mg(totalMg))]),
                        height: 52
                    ) {
                        add(food)
                    }
                    .accessibilityIdentifier("portion.confirm")
                    .padding(.top, 16)
                }
                .padding(EdgeInsets(top: 14, leading: 20, bottom: 34, trailing: 20))
            }
        }
    }

    private func favButton(_ food: FoodItem) -> some View {
        Button {
            toggleFavorite(food)
        } label: {
            SVGShape("M10 17 C10 17 2.5 12.5 2.5 7.5 C2.5 5 4.5 3 7 3 C8.3 3 9.4 3.6 10 4.5 C10.6 3.6 11.7 3 13 3 C15.5 3 17.5 5 17.5 7.5 C17.5 12.5 10 17 10 17 Z")
                .fill(isFavorite ? p.coral : .clear)
                .overlay(
                    SVGShape("M10 17 C10 17 2.5 12.5 2.5 7.5 C2.5 5 4.5 3 7 3 C8.3 3 9.4 3.6 10 4.5 C10.6 3.6 11.7 3 13 3 C15.5 3 17.5 5 17.5 7.5 C17.5 12.5 10 17 10 17 Z")
                        .stroke(p.coral, style: StrokeStyle(lineWidth: 1.7, lineJoin: .round))
                )
                .frame(width: 18, height: 18)
                .frame(width: 38, height: 38)
                .background(Circle().fill(p.chip))
                .overlay(Circle().strokeBorder(p.line, lineWidth: 1))
        }
        .buttonStyle(.pressScale(0.9))
        .accessibilityLabel(PinchLocalization.resolve(isFavorite ? "Remove from favorites" : "Pin to favorites"))
        .accessibilityIdentifier("portion.favorite")
    }

    private func toggleFavorite(_ food: FoodItem) {
        if let existing = favorites.first(where: { $0.foodID == food.id }) {
            modelContext.delete(existing)
            return
        }
        do {
            if try !FoodFavoriteStore.pin(food, in: modelContext, isPremium: subscriptions.isPremium) {
                ui.payOpen = true
            }
        } catch {
            ui.showToast("Could not save your favorite. Please try again.", "Try again")
        }
    }

    private func stepper(_ food: FoodItem) -> some View {
        HStack(spacing: 22) {
            stepButton(PinchLocalization.resolve("−")) {
                withAnimation(.snappy) { ui.servings = max(0.5, ui.servings - 0.5) }
            }
            VStack(spacing: 3) {
                PinchText("\(PinchFormat.servings(ui.servings))×")
                    .font(PinchFonts.display(40, .heavy))
                    .foregroundStyle(p.ink)
                    .contentTransition(.numericText())
                PinchText(PinchLocalization.format("{0} each", [food.displayServing]))
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }
            .frame(minWidth: 96)
            stepButton(PinchLocalization.resolve("+")) {
                withAnimation(.snappy) { ui.servings = min(4, ui.servings + 0.5) }
            }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PinchText(symbol)
                .pinchBody(22, .bold)
                .foregroundStyle(p.ink2)
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.sunk))
        }
        .buttonStyle(.pressScale(0.92))
    }

    private var mealPicker: some View {
        @Bindable var ui = ui
        return PinchSegmented(
            segments: Meal.allCases.map { PinchSegment(value: $0, label: $0.rawValue) },
            selection: $ui.meal,
            bordered: false
        )
    }

    private func add(_ food: FoodItem) {
        if food.id.hasPrefix(FatSecretConfig.idPrefix),
           !PremiumAccessPolicy.allows(.remoteFoodLogging, isPremium: subscriptions.isPremium) {
            ui.payOpen = true
            return
        }
        let day = ui.selectedDay()
        let stamp = timestamp(for: day)

        let entry = FoodRecommendations.entry(for: food, loggedAt: stamp, servings: ui.servings, meal: ui.meal)
        modelContext.insert(entry)
        let mg = totalMg
        ui.closeAllSheets()
        ui.showToast(PinchLocalization.format("{0}, {1} mg", [food.displayName, String(describing: PinchFormat.mg(mg))]), ToastCopy.line(forAdded: mg))
    }

}

// MARK: - Quick log (z50)

struct QuickLogSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionStore.self) private var subscriptions

    @Query private var customFoods: [CustomFood]

    @FocusState private var nameFocused: Bool

    private var mgValue: Int {
        SodiumConverter.sodiumMilligrams(from: ui.qlMg, unit: ui.qlUnit) ?? 0
    }
    private var valid: Bool {
        !ui.qlName.trimmingCharacters(in: .whitespaces).isEmpty && mgValue > 0
    }

    private var matchingShelfFood: CustomFood? {
        let name = ui.qlName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return customFoods.first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name
                && $0.mg == mgValue && $0.serving == "1 serving"
        }
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(onClose: { ui.qlOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Quick log") { ui.qlOpen = false }
                PinchText("Know the number? Skip the search.")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 2)

                PinchSegmented(
                    segments: [
                        PinchSegment(value: SodiumInputUnit.sodiumMilligrams, label: "Sodium mg"),
                        PinchSegment(value: SodiumInputUnit.saltGrams, label: "Salt g"),
                    ],
                    selection: $ui.qlUnit,
                    bordered: false
                )
                .padding(.top, 14)

                HStack(spacing: 10) {
                    SunkField(
                        label: "WHAT",
                        placeholder: "e.g. Diner omelette",
                        text: $ui.qlName,
                        focused: $nameFocused
                    )
                    .accessibilityIdentifier("quick-log.name")
                    SunkField(
                        label: ui.qlUnit.fieldLabel,
                        placeholder: "0",
                        text: $ui.qlMg,
                        numeric: true,
                        allowsDecimal: ui.qlUnit == .saltGrams
                    )
                    .accessibilityIdentifier("quick-log.amount")
                    .frame(width: 135)
                }
                .padding(.top, 16)

                if ui.qlUnit == .saltGrams, mgValue > 0 {
                    PinchText(PinchLocalization.format("That is about {0} mg sodium.", [String(describing: PinchFormat.mg(mgValue))]))
                        .pinchBody(11.5, .semibold)
                        .foregroundStyle(p.brand)
                        .padding(.top, 7)
                }

                PinchSegmented(
                    segments: Meal.allCases.map { PinchSegment(value: $0, label: $0.rawValue) },
                    selection: $ui.qlMeal,
                    bordered: false
                )
                .padding(.top, 12)

                HStack {
                    HStack(spacing: 8) {
                        SVGShape("M10 17 C10 17 2.5 12.5 2.5 7.5 C2.5 5 4.5 3 7 3 C8.3 3 9.4 3.6 10 4.5 C10.6 3.6 11.7 3 13 3 C15.5 3 17.5 5 17.5 7.5 C17.5 12.5 10 17 10 17 Z")
                            .stroke(p.coral, style: StrokeStyle(lineWidth: 1.7, lineJoin: .round))
                            .frame(width: 16, height: 16)
                        PinchText("Pin to favorites too")
                            .pinchBody(13, .semibold)
                            .foregroundStyle(p.ink)
                    }
                    Spacer()
                    PinchSwitch(isOn: Binding(
                        get: { ui.qlFav },
                        set: { newValue in
                            if newValue, matchingShelfFood == nil,
                               !PremiumAccessPolicy.allows(
                                    .unlimitedCustomFoods,
                                    isPremium: subscriptions.isPremium,
                                    customFoodCount: customFoods.count
                               ) {
                                ui.payOpen = true
                            } else {
                                ui.qlFav = newValue
                            }
                        }
                    ))
                    .accessibilityIdentifier("quick-log.favorite")
                }
                .padding(.top, 14)
                .padding(.horizontal, 2)

                PinchCTA(title: "Log it", height: 52, enabled: valid) {
                    submit()
                }
                .accessibilityIdentifier("quick-log.submit")
                .padding(.top, 16)
            }
            .padding(EdgeInsets(top: 14, leading: 20, bottom: 34, trailing: 20))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                nameFocused = true
            }
        }
    }

    private func submit() {
        guard valid else { return }
        let name = ui.qlName.trimmingCharacters(in: .whitespaces)
        let mg = mgValue
        let day = ui.selectedDay()
        let stamp = timestamp(for: day)

        if ui.qlFav {
            guard matchingShelfFood != nil || PremiumAccessPolicy.allows(
                .unlimitedCustomFoods,
                isPremium: subscriptions.isPremium,
                customFoodCount: customFoods.count
            ) else {
                ui.payOpen = true
                return
            }
            let food = matchingShelfFood ?? CustomFood(name: name, serving: "1 serving", mg: mg, usesDefaultServing: true)
            if matchingShelfFood == nil { modelContext.insert(food) }
            let foodID = food.id
            let descriptor = FetchDescriptor<Favorite>(predicate: #Predicate { $0.foodID == foodID })
            if ((try? modelContext.fetch(descriptor)) ?? []).isEmpty {
                modelContext.insert(Favorite(foodID: foodID))
            }
            modelContext.insert(LogEntry(foodID: food.id, servings: 1, meal: ui.qlMeal, loggedAt: stamp))
            ui.closeAllSheets()
            ui.showToast(PinchLocalization.format("{0}, {1} mg", [String(describing: name), String(describing: PinchFormat.mg(mg))]), "Logged and pinned to favorites.")
        } else {
            modelContext.insert(LogEntry(adhocName: name, adhocMg: mg, servings: 1, meal: ui.qlMeal, loggedAt: stamp))
            ui.closeAllSheets()
            ui.showToast(PinchLocalization.format("{0}, {1} mg", [String(describing: name), String(describing: PinchFormat.mg(mg))]), ToastCopy.line(forAdded: mg))
        }
    }
}

// MARK: - Create food (z50)

struct CreateFoodSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionStore.self) private var subscriptions

    @Query private var customFoods: [CustomFood]

    @FocusState private var nameFocused: Bool

    private var mgValue: Int {
        SodiumConverter.sodiumMilligrams(from: ui.cfMg, unit: ui.cfUnit) ?? 0
    }
    private var valid: Bool {
        !ui.cfName.trimmingCharacters(in: .whitespaces).isEmpty && mgValue > 0
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(onClose: { ui.cfOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "New food") { ui.cfOpen = false }
                PinchText("Goes on your shelf — searchable forever.")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 2)

                SunkField(
                    label: "NAME",
                    placeholder: "e.g. Mom's marinara",
                    text: $ui.cfName,
                    focused: $nameFocused
                )
                .padding(.top, 16)

                PinchSegmented(
                    segments: [
                        PinchSegment(value: SodiumInputUnit.sodiumMilligrams, label: "Sodium mg"),
                        PinchSegment(value: SodiumInputUnit.saltGrams, label: "Salt g"),
                    ],
                    selection: $ui.cfUnit,
                    bordered: false
                )
                .padding(.top, 12)

                HStack(spacing: 10) {
                    SunkField(label: "SERVING", placeholder: "1 cup", text: $ui.cfServe)
                    SunkField(
                        label: ui.cfUnit.fieldLabel,
                        placeholder: "0",
                        text: $ui.cfMg,
                        numeric: true,
                        allowsDecimal: ui.cfUnit == .saltGrams,
                        labelColor: p.brand,
                        highlighted: true
                    )
                }
                .padding(.top, 10)

                if ui.cfUnit == .saltGrams, mgValue > 0 {
                    PinchText(PinchLocalization.format("Stored as {0} mg sodium per serving.", [String(describing: PinchFormat.mg(mgValue))]))
                        .pinchBody(11.5, .semibold)
                        .foregroundStyle(p.brand)
                        .padding(.top, 7)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { ui.cfMore.toggle() }
                } label: {
                    PinchText(ui.cfMore ? "Hide calories & macros" : "Add calories & macros (optional)")
                        .pinchBody(12.5, .bold)
                        .foregroundStyle(p.brand)
                        .padding(2)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)

                if ui.cfMore {
                    HStack(spacing: 8) {
                        macroField("KCAL", $ui.cfCal)
                        macroField("CARBS G", $ui.cfCarb)
                        macroField("PROTEIN G", $ui.cfProt)
                        macroField("FAT G", $ui.cfFat)
                    }
                    .padding(.top, 8)
                }

                PinchCTA(title: "Add to my shelf", height: 52, enabled: valid) {
                    submit()
                }
                .padding(.top, 16)
            }
            .padding(EdgeInsets(top: 14, leading: 20, bottom: 34, trailing: 20))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                nameFocused = true
            }
        }
    }

    private func macroField(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            PinchText(label)
                .pinchBody(9, .bold, tracking: 0.08)
                .foregroundStyle(p.ink3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TextField("", text: text, prompt: PinchText("0").foregroundStyle(p.ink.opacity(0.38)))
                .pinchBody(14, .semibold)
                .foregroundStyle(p.ink)
                .keyboardType(.numberPad)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let filtered = newValue.filter(\.isNumber)
                    if filtered != newValue { text.wrappedValue = filtered }
                }
        }
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.sunk))
    }

    private func submit() {
        guard valid else { return }
        guard PremiumAccessPolicy.allows(
            .unlimitedCustomFoods,
            isPremium: subscriptions.isPremium,
            customFoodCount: customFoods.count
        ) else {
            ui.payOpen = true
            return
        }
        let name = ui.cfName.trimmingCharacters(in: .whitespaces)
        let serving = ui.cfServe.trimmingCharacters(in: .whitespaces)
        let food = CustomFood(
            name: name,
            serving: serving.isEmpty ? "1 serving" : serving,
            mg: mgValue,
            calories: Int(ui.cfCal),
            carbs: Int(ui.cfCarb),
            protein: Int(ui.cfProt),
            fat: Int(ui.cfFat),
            usesDefaultServing: serving.isEmpty
        )
        modelContext.insert(food)
        ui.cfOpen = false
        ui.showToast(PinchLocalization.format("{0} is on your shelf", [String(describing: name)]), "Search finds it anytime — tap to log it.")
    }
}
