//
//  LogSheets.swift
//  Sodium Tracker
//
//  The logging stack: the salt-shelf sheet (search + browse + actions), the
//  portion sheet, quick log, and create food.
//

import SwiftUI
import SwiftData

// MARK: - Log a food (z40)

struct LogSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui

    @Query(sort: \CustomFood.createdAt) private var customFoods: [CustomFood]
    @Query private var favorites: [Favorite]

    @FocusState private var searchFocused: Bool

    // FatSecret live search
    @State private var remoteResults: [RemoteFood] = []
    @State private var remoteSearching = false
    @State private var loadingRemoteID: String?

    private var query: String {
        ui.search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(topInset: 76, onClose: { ui.logOpen = false }) {
            VStack(spacing: 0) {
                HStack {
                    Text("Log a food")
                        .font(PinchFonts.display(21, .bold))
                        .foregroundStyle(p.ink)
                    Spacer()
                    SheetCloseButton { ui.logOpen = false }
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
                        resultSections
                        remoteSection
                    }
                    .padding(EdgeInsets(top: 6, leading: 20, bottom: 40, trailing: 20))
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                searchFocused = true
            }
        }
        .task(id: query) {
            await runRemoteSearch()
        }
    }

    /// Debounced FatSecret lookup; quietly does nothing without credentials.
    private func runRemoteSearch() async {
        guard FatSecretConfig.isEnabled, query.count >= 2 else {
            remoteResults = []
            remoteSearching = false
            return
        }
        remoteSearching = true
        defer { remoteSearching = false }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        do {
            let hits = try await FatSecretService.shared.search(query)
            guard !Task.isCancelled else { return }
            remoteResults = hits
        } catch {
            guard !Task.isCancelled else { return }
            remoteResults = []
        }
    }

    private var searchField: some View {
        @Bindable var ui = ui
        return HStack(spacing: 9) {
            SVGShape("M9 3.2 A5.8 5.8 0 1 0 9 14.8 A5.8 5.8 0 1 0 9 3.2 M13.5 13.5 L17 17")
                .stroke(p.ink3, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 17, height: 17)

            TextField("", text: $ui.search, prompt: Text("Search the salt shelf…").foregroundStyle(p.ink.opacity(0.38)))
                .pinchBody(15)
                .foregroundStyle(p.ink)
                .focused($searchFocused)
                .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    ui.search = ""
                } label: {
                    Text("Clear")
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            actionButton(
                lines: "Quick\nlog",
                icon: "M11.5 2.5 L4 11.5 H9 L8.5 17.5 L16 8.5 H11 Z",
                stroke: 1.7
            ) {
                ui.openQuickLog()
            }
            actionButton(
                lines: "Scan\nbarcode",
                icon: "M2.5 6 V3.5 C2.5 2.9 2.9 2.5 3.5 2.5 H6 M14 2.5 H16.5 C17.1 2.5 17.5 2.9 17.5 3.5 V6 M17.5 14 V16.5 C17.5 17.1 17.1 17.5 16.5 17.5 H14 M6 17.5 H3.5 C2.9 17.5 2.5 17.1 2.5 16.5 V14 M6 7 V13 M9 7 V13 M12 7 V13 M14 7 V13",
                stroke: 1.6
            ) {
                ui.startScan(.barcode)
            }
            actionButton(
                lines: "Snap\nlabel",
                icon: "M6.5 3.5 L7.6 2 H12.4 L13.5 3.5 H16 C17.1 3.5 18 4.4 18 5.5 V14.5 C18 15.6 17.1 16.5 16 16.5 H4 C2.9 16.5 2 15.6 2 14.5 V5.5 C2 4.4 2.9 3.5 4 3.5 Z M10 6.8 A3.2 3.2 0 1 0 10 13.2 A3.2 3.2 0 1 0 10 6.8",
                stroke: 1.6
            ) {
                ui.startScan(.label)
            }
            actionButton(
                lines: "New\nfood",
                icon: "M6.5 7.5 H13.5 V15.5 C13.5 16.6 12.6 17.5 11.5 17.5 H8.5 C7.4 17.5 6.5 16.6 6.5 15.5 Z M7.5 7.5 V5.5 H12.5 V7.5 M10 10.5 V14.5 M8 12.5 H12",
                stroke: 1.6
            ) {
                ui.openCreateFood()
            }
        }
    }

    private func actionButton(lines: String, icon: String, stroke: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                LineIcon(d: icon, size: 20, stroke: stroke, color: p.brand)
                Text(lines)
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
            return [Section(label: "\(hits.count) RESULT\(hits.count == 1 ? "" : "S")", rows: hits)]
        }
        var result: [Section] = []
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
        if !query.isEmpty && sections.isEmpty && remoteResults.isEmpty && !remoteSearching {
            noResults
        } else {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                Text(section.label)
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
                    Text(food.name)
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                    Text(food.serving)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(PinchFormat.mg(food.mg))
                        .pinchBody(15, .bold)
                        .monospacedDigit()
                        .foregroundStyle(p.tone(food.mg))
                    Text("MG")
                        .pinchBody(9.5, .bold, tracking: 0.08)
                        .foregroundStyle(p.ink3)
                }
            }
            .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    // MARK: FatSecret results

    @ViewBuilder private var remoteSection: some View {
        if !query.isEmpty, query.count >= 2, FatSecretConfig.isEnabled,
           remoteSearching || !remoteResults.isEmpty {
            Text("FROM FATSECRET")
                .pinchBody(11, .bold, tracking: 0.13)
                .foregroundStyle(p.ink3)
                .padding(EdgeInsets(top: 16, leading: 2, bottom: 8, trailing: 2))

            PinchCard {
                VStack(spacing: 0) {
                    if remoteResults.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching the big shelf…")
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

            Text("Powered by FatSecret")
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
                    Text(food.name)
                        .pinchBody(14, .semibold)
                        .foregroundStyle(p.ink)
                        .lineLimit(1)
                    Text(food.subtitle)
                        .pinchBody(11.5)
                        .foregroundStyle(p.ink3)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if loadingRemoteID == food.id {
                    ProgressView()
                        .controlSize(.small)
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
        .overlay(alignment: .top) {
            if !first { Rectangle().fill(p.line).frame(height: 1) }
        }
    }

    /// Fetches the food's sodium, then opens the portion sheet exactly like a
    /// local pick. Foods without sodium data fall back to Quick log.
    private func pickRemote(_ food: RemoteFood) {
        guard loadingRemoteID == nil else { return }
        loadingRemoteID = food.id
        Task {
            defer { loadingRemoteID = nil }
            do {
                let detail = try await FatSecretService.shared.details(id: food.id)
                ui.pick(FoodItem(
                    id: FatSecretConfig.idPrefix + food.id,
                    name: detail.name,
                    serving: detail.serving,
                    mg: detail.sodiumMg,
                    category: .custom
                ))
            } catch {
                ui.openQuickLog(prefillName: food.name)
            }
        }
    }

    private var noResults: some View {
        VStack(spacing: 0) {
            Text("Nothing salty by that name")
                .pinchBody(14.5, .semibold)
                .foregroundStyle(p.ink2)
            Text("Try \"soup\", \"pizza\" or \"ramen\" — or quick-log the mg yourself.")
                .pinchBody(12.5)
                .foregroundStyle(p.ink3)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
            Button {
                ui.openQuickLog(prefillName: query)
            } label: {
                Text("Quick log instead")
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

// MARK: - Portion sheet (z50)

struct PortionSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext

    @AppStorage(PinchDefaults.goalChoice) private var goalChoiceRaw = GoalChoice.fda.rawValue
    @AppStorage(PinchDefaults.customGoal) private var customGoal = PinchDefaults.customGoalDefault

    @Query private var favorites: [Favorite]

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
                            Text(food.name)
                                .font(PinchFonts.display(22, .bold))
                                .foregroundStyle(p.ink)
                            Text("per \(food.serving) · \(PinchFormat.mg(food.mg)) mg")
                                .pinchBody(12.5)
                                .foregroundStyle(p.ink3)
                        }
                        Spacer()
                        favButton(food)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    stepper(food)
                        .padding(.top, 18)
                        .padding(.bottom, 6)

                    (Text("\(PinchFormat.mg(totalMg)) mg")
                        .font(PinchFonts.display(19, .bold))
                        .foregroundStyle(p.tone(totalMg))
                     + Text(" · \(goal > 0 ? Int((Double(totalMg) / Double(goal) * 100).rounded()) : 0)% of your day")
                        .font(PinchFonts.body(12))
                        .foregroundStyle(p.ink3))
                        .monospacedDigit()
                        .padding(.bottom, 18)

                    mealPicker
                    PinchCTA(title: "Add · \(PinchFormat.mg(totalMg)) mg", height: 52) {
                        add(food)
                    }
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
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Pin to favorites")
    }

    private func toggleFavorite(_ food: FoodItem) {
        if let existing = favorites.first(where: { $0.foodID == food.id }) {
            modelContext.delete(existing)
            return
        }
        // Favoriting a FatSecret food saves it to the shelf first, so the
        // favorite resolves offline from then on.
        if food.id.hasPrefix(FatSecretConfig.idPrefix) {
            let descriptor = FetchDescriptor<CustomFood>()
            let existingShelf = (try? modelContext.fetch(descriptor)) ?? []
            if !existingShelf.contains(where: { $0.id == food.id }) {
                modelContext.insert(CustomFood(
                    id: food.id,
                    name: food.name,
                    serving: food.serving,
                    mg: food.mg
                ))
            }
        }
        modelContext.insert(Favorite(foodID: food.id))
    }

    private func stepper(_ food: FoodItem) -> some View {
        HStack(spacing: 22) {
            stepButton("−") {
                withAnimation(.snappy) { ui.servings = max(0.5, ui.servings - 0.5) }
            }
            VStack(spacing: 3) {
                Text("\(PinchFormat.servings(ui.servings))×")
                    .font(PinchFonts.display(40, .heavy))
                    .foregroundStyle(p.ink)
                    .contentTransition(.numericText())
                Text("\(food.serving) each")
                    .pinchBody(11.5)
                    .foregroundStyle(p.ink3)
            }
            .frame(minWidth: 96)
            stepButton("+") {
                withAnimation(.snappy) { ui.servings = min(4, ui.servings + 0.5) }
            }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
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
        let day = ui.selectedDay()
        let stamp = timestamp(for: day)

        if food.id.hasPrefix(FatSecretConfig.idPrefix),
           !customFoodExists(food.id) {
            // FatSecret foods that aren't on the shelf log as self-contained
            // entries carrying their own name, portion and sodium.
            modelContext.insert(LogEntry(
                adhocName: food.name,
                adhocMg: food.mg,
                adhocServing: food.serving,
                servings: ui.servings,
                meal: ui.meal,
                loggedAt: stamp
            ))
        } else {
            modelContext.insert(LogEntry(
                foodID: food.id,
                servings: ui.servings,
                meal: ui.meal,
                loggedAt: stamp
            ))
        }
        let mg = totalMg
        ui.closeAllSheets()
        ui.showToast("\(food.name) · \(PinchFormat.mg(mg)) mg", ToastCopy.line(forAdded: mg))
    }

    private func customFoodExists(_ id: String) -> Bool {
        let descriptor = FetchDescriptor<CustomFood>(predicate: #Predicate { $0.id == id })
        return ((try? modelContext.fetch(descriptor)) ?? []).isEmpty == false
    }
}

// MARK: - Quick log (z50)

struct QuickLogSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext

    @FocusState private var nameFocused: Bool

    private var mgValue: Int { Int(ui.qlMg) ?? 0 }
    private var valid: Bool {
        !ui.qlName.trimmingCharacters(in: .whitespaces).isEmpty && mgValue > 0
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(onClose: { ui.qlOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Quick log") { ui.qlOpen = false }
                Text("Know the number? Skip the search.")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 2)

                HStack(spacing: 10) {
                    SunkField(
                        label: "WHAT",
                        placeholder: "e.g. Diner omelette",
                        text: $ui.qlName,
                        focused: $nameFocused
                    )
                    SunkField(
                        label: "SODIUM MG",
                        placeholder: "0",
                        text: $ui.qlMg,
                        numeric: true
                    )
                    .frame(width: 135)
                }
                .padding(.top, 16)

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
                        Text("Pin to favorites too")
                            .pinchBody(13, .semibold)
                            .foregroundStyle(p.ink)
                    }
                    Spacer()
                    PinchSwitch(isOn: $ui.qlFav)
                }
                .padding(.top, 14)
                .padding(.horizontal, 2)

                PinchCTA(title: "Log it", height: 52, enabled: valid) {
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

    private func submit() {
        guard valid else { return }
        let name = ui.qlName.trimmingCharacters(in: .whitespaces)
        let mg = mgValue
        let day = ui.selectedDay()
        let stamp = timestamp(for: day)

        if ui.qlFav {
            let food = CustomFood(name: name, serving: "1 serving", mg: mg)
            modelContext.insert(food)
            modelContext.insert(Favorite(foodID: food.id))
            modelContext.insert(LogEntry(foodID: food.id, servings: 1, meal: ui.qlMeal, loggedAt: stamp))
            ui.closeAllSheets()
            ui.showToast("\(name) · \(PinchFormat.mg(mg)) mg", "Logged and pinned to favorites.")
        } else {
            modelContext.insert(LogEntry(adhocName: name, adhocMg: mg, servings: 1, meal: ui.qlMeal, loggedAt: stamp))
            ui.closeAllSheets()
            ui.showToast("\(name) · \(PinchFormat.mg(mg)) mg", ToastCopy.line(forAdded: mg))
        }
    }
}

// MARK: - Create food (z50)

struct CreateFoodSheet: View {
    @Environment(\.pinch) private var p
    @Environment(UIState.self) private var ui
    @Environment(\.modelContext) private var modelContext

    @FocusState private var nameFocused: Bool

    private var mgValue: Int { Int(ui.cfMg) ?? 0 }
    private var valid: Bool {
        !ui.cfName.trimmingCharacters(in: .whitespaces).isEmpty && mgValue > 0
    }

    var body: some View {
        @Bindable var ui = ui
        PinchSheet(onClose: { ui.cfOpen = false }) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "New food") { ui.cfOpen = false }
                Text("Goes on your shelf — searchable forever.")
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

                HStack(spacing: 10) {
                    SunkField(label: "SERVING", placeholder: "1 cup", text: $ui.cfServe)
                    SunkField(
                        label: "SODIUM MG",
                        placeholder: "0",
                        text: $ui.cfMg,
                        numeric: true,
                        labelColor: p.brand,
                        highlighted: true
                    )
                }
                .padding(.top, 10)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { ui.cfMore.toggle() }
                } label: {
                    Text(ui.cfMore ? "Hide calories & macros" : "Add calories & macros (optional)")
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
            Text(label)
                .pinchBody(9, .bold, tracking: 0.08)
                .foregroundStyle(p.ink3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TextField("", text: text, prompt: Text("0").foregroundStyle(p.ink.opacity(0.38)))
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
        let name = ui.cfName.trimmingCharacters(in: .whitespaces)
        let serving = ui.cfServe.trimmingCharacters(in: .whitespaces)
        let food = CustomFood(
            name: name,
            serving: serving.isEmpty ? "1 serving" : serving,
            mg: mgValue,
            calories: Int(ui.cfCal),
            carbs: Int(ui.cfCarb),
            protein: Int(ui.cfProt),
            fat: Int(ui.cfFat)
        )
        modelContext.insert(food)
        ui.cfOpen = false
        ui.showToast("\(name) is on your shelf", "Search finds it anytime — tap to log it.")
    }
}
