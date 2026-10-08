import SwiftUI
import SwiftData

struct RhythmScreen: View {
    @Environment(\.pinch) private var p
    @Environment(\.modelContext) private var context
    @Environment(UIState.self) private var ui
    @Environment(SubscriptionStore.self) private var subscriptions
    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]
    @Query private var favorites: [Favorite]
    @AppStorage(RhythmEngine.goalKey) private var storedGoal = 3
    @AppStorage(RhythmEngine.legacyCoolKey) private var legacyCoolDate = 0.0
    @AppStorage(PinchDefaults.lookupCount) private var lookupCount = 0
    @AppStorage(PinchDefaults.sleuthEarnedAt) private var sleuthDate = 0.0
    @State private var sheet: Sheet?
    @State private var saveFailed = false
    @State private var savedFood: FoodItem?
    private enum Sheet: String, Identifiable { case goal, collection; var id: String { rawValue } }
    private var goal: Int { RhythmEngine.validGoal(storedGoal) }
    private var badges: [BadgeState] {
        BadgeEngine.badges(entries: entries, customFoods: customFoods, lookupCount: lookupCount,
                           sleuthEarnedAt: sleuthDate == 0 ? nil : Date(timeIntervalSinceReferenceDate: sleuthDate),
                           streak: DayEngine.streak(entries),
                           legacyCoolEarnedAt: legacyCoolDate == 0 ? nil : Date(timeIntervalSinceReferenceDate: legacyCoolDate))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let week = RhythmEngine.week(entries, now: timeline.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionKicker(text: "SMALL STEPS, STILL COUNTING")
                        PinchText("Your rhythm").pinchDisplay(30, .bold).foregroundStyle(p.ink)
                            .accessibilityIdentifier("rhythm.title")
                        PinchText("A routine that fits your life.").pinchBody(14).foregroundStyle(p.ink2)
                    }.padding(.bottom, 4)
                    weeklyCard(week, now: timeline.date)
                    nextStep(week)
                    collectionCard
                    PinchText("Logging days show entries, not complete food diaries.")
                        .pinchBody(11.5).foregroundStyle(p.ink2)
                        .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 150)
            }.scrollIndicators(.hidden)
        }
        .onAppear { RhythmEngine.migrateLegacyAward(entries: entries, customFoods: customFoods) }
        .onChange(of: favorites.map(\.foodID)) { _, ids in
            if let savedFood, !ids.contains(savedFood.id) { self.savedFood = nil }
        }
        .sheet(item: $sheet) { selected in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        PinchText(selected == .goal ? "Make room for real life" : "Your milestones")
                            .pinchDisplay(23, .bold).foregroundStyle(p.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button { sheet = nil } label: {
                            Image(systemName: "xmark").font(.system(size: 15, weight: .bold))
                                .frame(width: 44, height: 44).background(p.sunk, in: Circle())
                        }.frame(width: 44, height: 44).layoutPriority(1).foregroundStyle(p.ink2)
                            .accessibilityLabel(PinchLocalization.resolve("Close"))
                            .accessibilityIdentifier("rhythm.sheet.close")
                    }
                    if selected == .goal { goalEditor } else { collection }
                }.padding(24)
            }.background(p.bg).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
    }

    private func weeklyCard(_ week: RhythmEngine.Week, now: Date) -> some View {
        PinchCard(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionKicker(text: "This week")
                    Spacer()
                    Button { sheet = .goal } label: {
                        PinchText("Edit goal").pinchBody(13, .bold).padding(.vertical, 12)
                    }.foregroundStyle(p.brand).accessibilityIdentifier("rhythm.edit-goal")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(PinchLocalization.number(week.count)).font(PinchFonts.display(44, .heavy))
                        .monospacedDigit().foregroundStyle(p.ink).accessibilityIdentifier("rhythm.logged-days")
                    PinchText("Days with entries").pinchBody(14, .semibold).foregroundStyle(p.ink2)
                    PinchText(goalLabel(goal)).pinchBody(12.5).foregroundStyle(p.ink2)
                        .accessibilityIdentifier("rhythm.goal-summary")
                }
                HStack(spacing: 4) {
                    ForEach(week.dates, id: \.self) { date in
                        let logged = week.logged.contains(date)
                        let today = Calendar.current.isDate(date, inSameDayAs: now)
                        VStack(spacing: 7) {
                            ZStack {
                                Circle().fill(logged ? p.brand : p.sunk)
                                if logged { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(p.onBrand) }
                            }.frame(width: 28, height: 28)
                                .overlay(Circle().strokeBorder(today ? p.brandDeep : .clear, lineWidth: 2).padding(-3))
                                .opacity(date > now ? 0.5 : 1)
                            Text(date.formatted(.dateTime.weekday(.narrow).locale(PinchLocalization.locale)))
                                .pinchBody(11, .bold).foregroundStyle(p.ink2)
                        }.frame(maxWidth: .infinity).padding(.vertical, 4)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month().day().locale(PinchLocalization.locale)))
                            .accessibilityValue(PinchLocalization.resolve(logged ? "Logged" : "No entries"))
                    }
                }
                Rectangle().fill(p.line).frame(height: 1)
                Label {
                    PinchText(week.count >= goal ? "Your weekly goal is met. Keep going at your pace." :
                                week.isReturning ? "A missed day doesn’t erase your progress." : "Every day you log adds to your picture.")
                        .pinchBody(13).foregroundStyle(p.ink2).fixedSize(horizontal: false, vertical: true)
                } icon: { Image(systemName: week.count >= goal ? "checkmark.circle.fill" : "leaf").foregroundStyle(p.brand) }
            }.padding(20)
        }
    }

    private func nextStep(_ week: RhythmEngine.Week) -> some View {
        let suggestion = RhythmEngine.suggestion(entries: week.entries, favorites: favorites, customFoods: customFoods)
        return PinchCard(radius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                SectionKicker(text: "MAKE NEXT TIME EASIER")
                PinchText(savedFood != nil ? "Ready for next time" : suggestion != nil ? "One less search tomorrow" : "Start with your next meal")
                    .pinchDisplay(20, .bold).foregroundStyle(p.ink)
                if let savedFood {
                    PinchText(PinchLocalization.format("{0} is saved in Favorites and ready for quick add.", [savedFood.displayName]))
                        .pinchBody(13).foregroundStyle(p.ink2)
                } else if let suggestion {
                    PinchText(PinchLocalization.format("You logged {0} {1} times this week. Save it for easy access.",
                                                       [suggestion.food.displayName, PinchLocalization.number(suggestion.count)]))
                        .pinchBody(13).foregroundStyle(p.ink2)
                } else {
                    PinchText(week.isReturning ? "Your earlier effort still counts. There’s no catch-up to do." : "Log a food now. Your familiar foods will help shape your next steps.")
                        .pinchBody(13).foregroundStyle(p.ink2)
                }
                if saveFailed {
                    PinchText("Could not save your favorite. Please try again.").pinchBody(12).foregroundStyle(p.coral)
                }
                PinchCTA(title: savedFood != nil || suggestion == nil ? "Log a food" : "Pin to favorites", height: 48) {
                    if savedFood == nil, let suggestion {
                        do {
                            if try FoodFavoriteStore.pin(suggestion.food, in: context, isPremium: subscriptions.isPremium) {
                                saveFailed = false; savedFood = suggestion.food
                            } else { ui.payOpen = true }
                        } catch { saveFailed = true }
                    } else { ui.selOffset = 0; ui.openFoodLog() }
                }.accessibilityIdentifier("rhythm.next-step")
            }.padding(20)
        }
    }

    private var collectionCard: some View {
        let earned = badges.filter(\.earned).count
        return Button { sheet = .collection } label: {
            PinchCard(radius: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "rosette").font(.system(size: 28)).foregroundStyle(p.amber)
                        VStack(alignment: .leading, spacing: 4) {
                            PinchText("Your milestones").pinchBody(17, .bold).foregroundStyle(p.ink)
                            PinchText(earned == badges.count ? "All milestones earned. Always yours." :
                                        PinchLocalization.format("{0} of {1} earned", [PinchLocalization.number(earned), PinchLocalization.number(badges.count)]))
                                .pinchBody(12.5).foregroundStyle(p.ink2)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(badges) { badge in
                            Image(systemName: badge.earned ? "checkmark.seal.fill" : "seal")
                                .font(.system(size: 23)).foregroundStyle(badge.earned ? p.brand : p.ink3)
                                .frame(maxWidth: .infinity)
                        }
                    }.accessibilityHidden(true)
                    HStack {
                        PinchText("View collection").pinchBody(13, .bold)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    }.foregroundStyle(p.ink)
                }.padding(20).background(p.amberSoft.opacity(0.35))
            }.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }.buttonStyle(.pressScale(0.98)).accessibilityIdentifier("rhythm.collection")
    }

    private func goalLabel(_ value: Int) -> String {
        PinchLocalization.format("Your weekly logging goal: {0} days", [PinchLocalization.number(value)])
    }

    private var goalEditor: some View {
        VStack(alignment: .leading, spacing: 18) {
            PinchText("Choose a manageable goal. These days do not need to be consecutive.").pinchBody(14).foregroundStyle(p.ink2)
            ForEach(RhythmEngine.goals, id: \.self) { value in
                Button { storedGoal = value } label: {
                    HStack {
                        PinchText(goalLabel(value)).pinchBody(15, .semibold).multilineTextAlignment(.leading)
                        Spacer(minLength: 12)
                        Image(systemName: value == goal ? "checkmark.circle.fill" : "circle")
                    }.foregroundStyle(value == goal ? p.brand : p.ink2)
                        .padding(16).frame(maxWidth: .infinity, minHeight: 52)
                        .background(value == goal ? p.brandSoft : p.sunk, in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain).accessibilityIdentifier("rhythm.goal-\(value)")
                    .accessibilityAddTraits(value == goal ? [.isSelected] : [])
            }
            PinchText("This is a logging goal, not a sodium target. Change it whenever you need.").pinchBody(13).foregroundStyle(p.ink2)
            PinchCTA(title: "Done") { sheet = nil }.accessibilityIdentifier("rhythm.goal.done")
        }
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PinchText("Milestones celebrate logging, not how little you eat.").pinchBody(13).foregroundStyle(p.ink2)
            ForEach(badges) { badge in
                PinchCard(radius: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: badge.earned ? "checkmark.seal.fill" : "seal")
                            .font(.system(size: 28)).foregroundStyle(badge.earned ? p.brand : p.ink3)
                        VStack(alignment: .leading, spacing: 5) {
                            PinchText(badge.name).pinchBody(16, .bold).foregroundStyle(p.ink)
                            PinchText(badge.detail).pinchBody(13).foregroundStyle(p.ink2)
                            PinchText(badge.earnedDate.map {
                                PinchLocalization.format("EARNED {0}", [PinchFormat.badgeDate($0)])
                            } ?? badge.progressNote ?? "").pinchBody(12, .semibold).foregroundStyle(badge.earned ? p.brand : p.ink2)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(16)
                }.accessibilityIdentifier("rhythm.badge-\(badge.id)")
            }
        }
    }
}
