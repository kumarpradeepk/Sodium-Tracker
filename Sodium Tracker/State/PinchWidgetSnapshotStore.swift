import Foundation
import WidgetKit

enum PinchWidgetSnapshotStore {
    static let appGroup = "group.com.kabi.sodium.tracker"

    static func write(consumed: Int, goal: Int, streak: Int, isPremium: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        // Match Android: clear premium values when access expires so a stale
        // widget cannot expose locked data.
        defaults.set(isPremium ? consumed : 0, forKey: "consumed")
        defaults.set(isPremium ? goal : 0, forKey: "goal")
        defaults.set(isPremium ? goal - consumed : 0, forKey: "remaining")
        defaults.set(streak, forKey: "streak")
        defaults.set(isPremium, forKey: "premium")
        WidgetCenter.shared.reloadTimelines(ofKind: "PinchSodiumWidget")
    }
}
