//
//  PinchWidgets.swift
//  Sodium Tracker Widgets
//

import SwiftUI
import WidgetKit

private enum PinchWidgetStore {
    static let appGroup = "group.com.kabi.sodium.tracker"
    static let key = "pinch.widget.snapshot.v1"

    struct Snapshot: Codable {
        let consumed: Int
        let goal: Int
        let remaining: Int
        let streak: Int
        let isPremium: Bool
    }

    static var current: Snapshot {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return Snapshot(consumed: 0, goal: 0, remaining: 0, streak: 0, isPremium: false)
        }
        return snapshot
    }
}

private struct PinchWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PinchWidgetStore.Snapshot
}

private struct PinchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinchWidgetEntry {
        PinchWidgetEntry(date: .now, snapshot: .init(consumed: 902, goal: 1500, remaining: 598, streak: 14, isPremium: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (PinchWidgetEntry) -> Void) {
        completion(PinchWidgetEntry(date: .now, snapshot: PinchWidgetStore.current))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinchWidgetEntry>) -> Void) {
        let entry = PinchWidgetEntry(date: .now, snapshot: PinchWidgetStore.current)
        // A refresh at midnight keeps the day boundary correct even if the app
        // has not been opened. Writes from the app still trigger immediate reloads.
        let next = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

private enum PinchWidgetCopy {
    static var language: String { Locale.current.language.languageCode?.identifier ?? "en" }
    static func localized(_ english: String, de: String, ja: String) -> String {
        switch language {
        case "de": return de
        case "ja": return ja
        default: return english
        }
    }
    static var plus: String { localized("Pinch Plus", de: "Pinch Plus", ja: "Pinch Plus") }
    static var unlock: String { localized("Unlock widgets", de: "Widgets freischalten", ja: "ウィジェットを解除") }
    static var today: String { localized("Today", de: "Heute", ja: "今日") }
    static var left: String { localized("left", de: "übrig", ja: "残り") }
    static var over: String { localized("over", de: "über", ja: "超過") }
    static func of(_ goal: Int) -> String {
        localized("of \(goal) mg", de: "von \(goal) mg", ja: "\(goal) mg中")
    }
    static func streak(_ value: Int) -> String {
        localized("✦ \(value)-day streak", de: "✦ \(value)-Tage-Serie", ja: "✦ \(value)日連続")
    }
}

private struct PinchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PinchWidgetEntry

    private var snapshot: PinchWidgetStore.Snapshot { entry.snapshot }
    private var progress: Double {
        guard snapshot.goal > 0 else { return 0 }
        return min(max(Double(snapshot.consumed) / Double(snapshot.goal), 0), 1)
    }
    private var remainingText: String {
        let value = abs(snapshot.remaining)
        return "\(value.formatted()) mg \(snapshot.remaining >= 0 ? PinchWidgetCopy.left : PinchWidgetCopy.over)"
    }

    var body: some View {
        Group {
            if snapshot.isPremium {
                premiumView
            } else {
                lockedView
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.965, green: 0.976, blue: 0.988)
        }
        .widgetURL(URL(string: snapshot.isPremium ? "sodiumtracker://today" : "sodiumtracker://paywall"))
    }

    @ViewBuilder private var premiumView: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                header
                Spacer(minLength: 2)
                Text(snapshot.consumed.formatted())
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.24))
                    .minimumScaleFactor(0.7)
                Text(PinchWidgetCopy.of(snapshot.goal))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(remainingText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.13, green: 0.47, blue: 0.73))
            }
        case .systemMedium:
            HStack(spacing: 14) {
                ring
                    .frame(width: 82, height: 82)
                VStack(alignment: .leading, spacing: 5) {
                    header
                    Text(snapshot.consumed.formatted())
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.24))
                    Text(PinchWidgetCopy.of(snapshot.goal))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(remainingText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.13, green: 0.47, blue: 0.73))
                }
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                header
                HStack(spacing: 16) {
                    ring.frame(width: 118, height: 118)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(snapshot.consumed.formatted())
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.24))
                        Text(PinchWidgetCopy.of(snapshot.goal))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(remainingText)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.13, green: 0.47, blue: 0.73))
                    }
                }
                Text("Pinch keeps your sodium count close.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(PinchWidgetCopy.today)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.24))
            Spacer(minLength: 0)
            Text(PinchWidgetCopy.streak(snapshot.streak))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.70, green: 0.47, blue: 0.09))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(red: 1.0, green: 0.94, blue: 0.78), in: Capsule())
        }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Color(red: 0.86, green: 0.90, blue: 0.94), lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(red: 0.13, green: 0.47, blue: 0.73), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("Na")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.13, green: 0.47, blue: 0.73))
        }
    }

    private var lockedView: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(Color(red: 0.87, green: 0.93, blue: 0.98)).frame(width: 48, height: 48)
                Text("✦").font(.system(size: 24, weight: .bold)).foregroundStyle(Color(red: 0.13, green: 0.47, blue: 0.73))
            }
            Text(PinchWidgetCopy.plus)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.24))
            Text(PinchWidgetCopy.unlock)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PinchWidgets: Widget {
    let kind = "PinchWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PinchWidgetProvider()) { entry in
            PinchWidgetView(entry: entry)
        }
        .configurationDisplayName("Pinch sodium widget")
        .description("A calm glance at your daily sodium budget. Pinch Plus required.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct PinchWidgetsBundle: WidgetBundle {
    var body: some Widget { PinchWidgets() }
}
