//
//  AwardsScreen.swift
//  Sodium Tracker
//
//  "Keep shaking": the streak card with its week dots and the badge grid.
//

import SwiftUI
import SwiftData

struct AwardsScreen: View {
    @Environment(\.pinch) private var p

    @Query(sort: \LogEntry.loggedAt) private var entries: [LogEntry]
    @Query private var customFoods: [CustomFood]

    private var streak: Int { DayEngine.streak(entries) }

    private var badges: [BadgeState] {
        let defaults = UserDefaults.standard
        let sleuthStamp = defaults.double(forKey: PinchDefaults.sleuthEarnedAt)
        return BadgeEngine.badges(
            entries: entries,
            customFoods: customFoods,
            lookupCount: defaults.integer(forKey: PinchDefaults.lookupCount),
            sleuthEarnedAt: sleuthStamp == 0 ? nil : Date(timeIntervalSinceReferenceDate: sleuthStamp),
            streak: streak
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PinchText("SMALL WINS")
                    .pinchBody(11, .bold, tracking: 0.14)
                    .foregroundStyle(p.ink3)
                PinchText("Awards")
                    .pinchDisplay(30, .bold)
                    .foregroundStyle(p.ink)
                    .padding(.top, 2)
                PinchText("Quiet proof that showing up counts.")
                    .pinchBody(12.5)
                    .foregroundStyle(p.ink3)
                    .padding(.top, 3)

                streakCard
                    .padding(.top, 16)

                SectionKicker(text: "YOUR BADGES")
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                badgeGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Streak card

    private var streakCard: some View {
        PinchCard(radius: 20) {
            VStack(spacing: 0) {
                SVGShape("M10 1.5 L12.2 7.8 L18.5 10 L12.2 12.2 L10 18.5 L7.8 12.2 L1.5 10 L7.8 7.8 Z")
                    .fill(p.amber)
                    .frame(width: 30, height: 30)
                    .padding(.bottom, 2)

                PinchText("\(streak)")
                    .font(PinchFonts.display(56, .heavy))
                    .tracking(56 * -0.03)
                    .monospacedDigit()
                    .foregroundStyle(p.ink)

                PinchText("day logging streak")
                    .pinchBody(13.5, .semibold)
                    .foregroundStyle(p.ink2)
                    .padding(.top, 4)

                weekDots
                    .padding(.top, 16)

                streakFooter
                    .padding(.top, 14)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(alignment: .top) {
                RadialGradient(
                    colors: [p.amberSoft, p.amberSoft.opacity(0)],
                    center: .top,
                    startRadius: 0,
                    endRadius: 260
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekDots: some View {
        let calendar = Calendar.current
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) })
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)  // 1 = Sunday

        return HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { i in
                let offset = i + 1 - weekday  // Sunday of this week … Saturday
                let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
                let logged = loggedDays.contains(date)
                let isToday = offset == 0
                let future = offset > 0

                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(logged ? p.brand : p.sunk)
                        Circle()
                            .strokeBorder(isToday ? p.brandDeep : .clear, lineWidth: 2)
                        if logged {
                            SVGShape("M2 6.5 L4.8 9 L10 3", viewBox: CGSize(width: 12, height: 12))
                                .stroke(p.onBrand, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .opacity(future ? 0.45 : 1)

                    PinchText(["S", "M", "T", "W", "T", "F", "S"][i])
                        .pinchBody(9.5, .bold)
                        .foregroundStyle(p.ink3)
                }
            }
        }
    }

    private var streakFooter: some View {
        let next = nextMilestone
        return Group {
            if let next {
                (PinchText(next.have).bold().foregroundStyle(p.ink2)
                 + PinchText(" is yours — \(next.remaining) more day\(next.remaining == 1 ? "" : "s") to ")
                 + PinchText(next.name).bold().foregroundStyle(p.ink2))
                    .pinchBody(12)
                    .foregroundStyle(p.ink3)
            } else {
                PinchText("Every streak badge is yours. Keep shaking.")
                    .pinchBody(12)
                    .foregroundStyle(p.ink3)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var nextMilestone: (have: String, name: String, remaining: Int)? {
        let milestones: [(Int, String)] = [(3, "Hat Trick"), (7, "Salt Week"), (30, "Steady Shaker")]
        guard let nextIdx = milestones.firstIndex(where: { streak < $0.0 }) else { return nil }
        let next = milestones[nextIdx]
        let have = nextIdx == 0 ? "First Pinch" : milestones[nextIdx - 1].1
        return (have, next.1, next.0 - streak)
    }

    // MARK: - Badges

    private var badgeGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(badges) { badge in
                badgeCard(badge)
            }
        }
    }

    private func badgeCard(_ badge: BadgeState) -> some View {
        PinchCard(padding: EdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14)) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(badge.earned ? p.brandSoft : .clear)
                    if badge.earned {
                        Circle().strokeBorder(p.brand, lineWidth: 2)
                    } else {
                        Circle().strokeBorder(p.grain, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    }
                    if badge.iconPath.isEmpty {
                        PinchText(badge.iconText)
                            .font(PinchFonts.display(14, .heavy))
                            .foregroundStyle(badge.earned ? p.brand : p.ink3)
                    } else {
                        LineIcon(
                            d: badge.iconPath,
                            size: 26,
                            stroke: 1.7,
                            color: badge.earned ? p.brand : p.ink3
                        )
                    }
                }
                .frame(width: 52, height: 52)

                PinchText(badge.name)
                    .pinchBody(13, .bold)
                    .foregroundStyle(p.ink)
                    .padding(.top, 10)

                PinchText(badge.detail)
                    .pinchBody(11)
                    .foregroundStyle(p.ink3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 3)

                PinchText(statusLine(badge))
                    .pinchBody(10.5, .bold)
                    .foregroundStyle(badge.earned ? p.brand : p.ink3)
                    .padding(.top, 7)
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(badge.earned ? 1 : 0.62)
    }

    private func statusLine(_ badge: BadgeState) -> String {
        if let date = badge.earnedDate {
            return "EARNED \(PinchFormat.badgeDate(date))"
        }
        return (badge.progressNote ?? "").uppercased()
    }
}
