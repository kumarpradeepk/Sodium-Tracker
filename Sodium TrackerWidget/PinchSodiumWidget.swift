import SwiftUI
import WidgetKit

private let pinchAppGroup = "group.com.kabi.sodium.tracker"

private struct PinchWidgetEntry: TimelineEntry {
    let date: Date
    let consumed: Int
    let goal: Int
    let streak: Int
    let premium: Bool
}

private struct PinchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinchWidgetEntry {
        PinchWidgetEntry(date: .now, consumed: 870, goal: 2300, streak: 3, premium: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (PinchWidgetEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinchWidgetEntry>) -> Void) {
        let entry = read()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func read() -> PinchWidgetEntry {
        let defaults = UserDefaults(suiteName: pinchAppGroup)
        return PinchWidgetEntry(
            date: .now,
            consumed: defaults?.integer(forKey: "consumed") ?? 0,
            goal: max(1, defaults?.integer(forKey: "goal") ?? 2300),
            streak: defaults?.integer(forKey: "streak") ?? 0,
            premium: defaults?.bool(forKey: "premium") ?? false
        )
    }
}

private struct PinchWidgetView: View {
    let entry: PinchWidgetEntry

    private var progress: Double { min(1, Double(entry.consumed) / Double(entry.goal)) }
    private var remaining: Int { entry.goal - entry.consumed }

    var body: some View {
        if entry.premium {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label(localized("Today"), systemImage: "circle.grid.cross.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(localized("\(entry.streak)-day streak"))
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                Text(entry.consumed.formatted())
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                Text(localized("of \(entry.goal.formatted()) mg"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: progress)
                    .tint(Color(red: 0.12, green: 0.46, blue: 0.42))
                Text(localized(remaining >= 0 ? "\(remaining.formatted()) mg left" : "\((-remaining).formatted()) mg over"))
                    .font(.caption.bold())
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.orange)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.12, green: 0.46, blue: 0.42))
                Text("Pinch Plus")
                    .font(.headline)
                Text(localized("Unlock widgets"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func localized(_ value: String) -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        if value == "Today" { return language == "de" ? "Heute" : language == "ja" ? "今日" : value }
        if value == "Unlock widgets" { return language == "de" ? "Widgets freischalten" : language == "ja" ? "ウィジェットを解除" : value }
        if value.hasSuffix("-day streak"), let number = value.split(separator: "-").first {
            return language == "de" ? "\(number)-Tage-Serie" : language == "ja" ? "\(number)日連続" : value
        }
        if value.hasPrefix("of ") { return language == "de" ? value.replacingOccurrences(of: "of ", with: "von ") : language == "ja" ? String(value.dropFirst(3)) + "中" : value }
        if value.hasSuffix(" mg left") { let amount = value.dropLast(8); return language == "de" ? "\(amount) mg übrig" : language == "ja" ? "残り \(amount) mg" : value }
        if value.hasSuffix(" mg over") { let amount = value.dropLast(8); return language == "de" ? "\(amount) mg darüber" : language == "ja" ? "\(amount) mg超過" : value }
        return value
    }
}

@main
struct PinchSodiumWidget: Widget {
    let kind = "PinchSodiumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PinchWidgetProvider()) { entry in
            PinchWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Pinch Sodium")
        .description("See today's sodium, budget, and streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
