//
//  SaltyTests.swift
//  Sodium TrackerTests
//
//  The Salty dashboard's physics and copy. These lock the values that make the
//  port faithful — if a constant drifts from the prototype, one of these fails.
//  Mirrors `SaltyTests.kt` on Android; both must stay in sync.
//

import Testing
import Foundation
import SwiftUI
@testable import Sodium_Tracker

@Suite("Salty spring integrator")
struct SaltySpringTests {

    @Test func ringSpringConvergesToTarget() {
        var s = SpringValue(0, k: SaltySpring.fracK, c: SaltySpring.fracC)
        s.target = 0.645
        for _ in 0..<120 { s.step(1.0 / 60) }   // 2 seconds
        #expect(abs(s.x - 0.645) < 0.645 * 0.01)
    }

    @Test func ringSpringOvershoots() {
        // k40 / c8.5 is underdamped — the design wants the slight bounce.
        var s = SpringValue(0, k: SaltySpring.fracK, c: SaltySpring.fracC)
        s.target = 1.0
        var peak = 0.0
        for _ in 0..<240 { s.step(1.0 / 60); peak = max(peak, s.x) }
        #expect(peak > 1.0)
    }

    @Test func impulseChangesVelocityNotPosition() {
        var s = SpringValue(0, k: SaltySpring.hopK, c: SaltySpring.hopC)
        s.impulse(-230)
        #expect(s.v == -230)
        #expect(s.x == 0)
    }

    @Test func settleKillsMotion() {
        var s = SpringValue(0, k: SaltySpring.fracK, c: SaltySpring.fracC)
        s.target = 1.0
        for _ in 0..<10 { s.step(1.0 / 60) }
        s.settle(at: 0.5)
        #expect(s.x == 0.5)
        #expect(s.v == 0)
    }

    @Test func constantsMatchThePrototype() {
        #expect(SaltySpring.fracK == 40 && SaltySpring.fracC == 8.5)
        #expect(SaltySpring.hopK == 190 && SaltySpring.hopC == 12)
        #expect(SaltySpring.pulseK == 160 && SaltySpring.pulseC == 10)
        #expect(SaltySpring.tiltK == 120 && SaltySpring.tiltC == 11)
        #expect(SaltySpring.capK == 200 && SaltySpring.capC == 12)
        #expect(SaltySpring.armK == 90 && SaltySpring.armC == 7)
        #expect(SaltySpring.armRest == 30)
        #expect(SaltySpring.maxTimestep == 0.033)
        #expect(SaltySpring.loadInDelay == 0.42)
    }
}

@Suite("Salty engine")
struct SaltyEngineTests {

    @Test func ringHoldsAtZeroUntilTheLoadInDelay() {
        let engine = SaltyEngine()
        engine.fracTarget = 0.645
        // Just before the 0.42 s kick the arc has not started.
        for _ in 0..<24 { engine.advance(1.0 / 60) }   // 0.40 s
        #expect(engine.fraction == 0)
        // Well after, it has sprung to the live value.
        for _ in 0..<180 { engine.advance(1.0 / 60) }
        #expect(abs(engine.fraction - 0.645) < 0.01)
    }

    /// Mirrors mount order: data lands first, then the ring is settled to it.
    private func settled(at fraction: Double) -> SaltyEngine {
        let engine = SaltyEngine()
        engine.fracTarget = fraction
        engine.settleFraction()
        engine.advance(1.0 / 60)
        return engine
    }

    @Test func mascotRidesTheArcTip() {
        let engine = settled(at: 0.25)
        // A quarter turn from 12 o'clock is 3 o'clock: (160+134, 160).
        #expect(abs(engine.mascotPoint.x - 294) < 1)
        #expect(abs(engine.mascotPoint.y - 160) < 1)
    }

    @Test func overflowWrapsPastTwelveOClock() {
        let engine = settled(at: 1.25)
        #expect(engine.arcFraction == 1.0)
        #expect(abs(engine.overFraction - 0.25) < 0.001)
        // The mascot keeps going round rather than sticking at the top.
        #expect(abs(engine.mascotPoint.x - 294) < 1)
    }

    @Test func flashRevertsToTheRestingFace() {
        let engine = SaltyEngine()
        engine.setRestingMood(.worried)
        engine.flash(.joy, seconds: 0.5)
        engine.advance(0.01)
        #expect(engine.features.joyOp > 0)
        for _ in 0..<60 { engine.advance(1.0 / 60) }   // past the flash + crossfade
        #expect(engine.features.sweatOp > 0.8)         // worried again
    }

    @Test func counterIsTiedToTheSpring() {
        let engine = settled(at: 967.0 / 1500.0)
        #expect(engine.shown(budget: 1500) == 967)
    }
}

@Suite("Salty model")
struct SaltyModelTests {

    private func food(_ mg: Int) -> FoodItem {
        FoodItem(id: "f\(mg)", name: "Food \(mg)", serving: "1 serving", mg: mg, category: .meal)
    }

    @Test func restingMoodFollowsTheDesignThresholds() {
        #expect(SaltyModel.restingMood(remaining: -1, isToday: true) == .worried)
        #expect(SaltyModel.restingMood(remaining: 149, isToday: true) == .concern)
        #expect(SaltyModel.restingMood(remaining: 150, isToday: true) == .happy)
        // Past days never show concern — only over-budget worries Salty.
        #expect(SaltyModel.restingMood(remaining: 10, isToday: false) == .happy)
        #expect(SaltyModel.restingMood(remaining: -10, isToday: false) == .worried)
    }

    @Test func todayBubbleCoversEveryBranchVerbatim() {
        #expect(SaltyModel.todayBubble(remaining: -77, fits: 0)
                == "77 mg over budget. Ease up tonight — tomorrow resets.")
        #expect(SaltyModel.todayBubble(remaining: 533, fits: 0)
                == "533 mg left — under every usual pick. Go fresh for dinner.")
        #expect(SaltyModel.todayBubble(remaining: 250, fits: 1)
                == "250 mg left — a light bite still fits.")
        #expect(SaltyModel.todayBubble(remaining: 1000, fits: 3)
                == "1,000 mg left — 3 of your usual picks fit.")
    }

    @Test func pastBubbleCoversEveryBranch() {
        #expect(SaltyModel.pastBubble(total: 0, remaining: 100, isEmpty: true)
                == "A quiet page in the log book.")
        #expect(SaltyModel.pastBubble(total: 1840, remaining: -340, isEmpty: false)
                == "Finished 340 mg over budget.")
        #expect(SaltyModel.pastBubble(total: 1320, remaining: 180, isEmpty: false)
                == "Closed at 1,320 — 180 mg under budget. Nice save.")
    }

    @Test func chipsOnlyFitOnTodayAndWithinBudget() {
        #expect(SaltyModel.fits(mg: 610, remaining: 610, isToday: true))
        #expect(!SaltyModel.fits(mg: 611, remaining: 610, isToday: true))
        #expect(!SaltyModel.fits(mg: 10, remaining: 610, isToday: false))
    }

    @Test func fitCountDrivesTheUsualPicksLine() {
        let foods = [food(610), food(740), food(680), food(890), food(960)]
        #expect(SaltyModel.fitCount(foods, remaining: 533) == 0)
        #expect(SaltyModel.fitCount(foods, remaining: 740) == 3)
        #expect(SaltyModel.fitCount(foods, remaining: 1000) == 5)
    }

    @Test func quickAddsFallBackToTheDesignDefaults() {
        let picks = SaltyModel.quickAdds(from: [], customFoods: [])
        #expect(picks.map(\.name) == ["Fresh dinner", "Soup cup", "Light snack"])
        #expect(picks.map(\.mg) == [380, 290, 150])
    }
}

@Suite("Salty tokens")
struct SaltyTokenTests {

    @Test func saltyLightMatchesTheDesignHexes() {
        let s = SaltyTokens.resolve(.salty, dark: false)
        #expect(s.blue == Color(hex: 0x2E6FBD))
        #expect(s.ink == Color(hex: 0x1F3A5C))
        #expect(s.screenBg == Color(hex: 0xEDF1F6))
        #expect(s.disc == Color(hex: 0xDFE8F3))
        #expect(s.track == Color(hex: 0xC7D3E3))
        #expect(s.amberArc == Color(hex: 0xDFA32B))
        #expect(s.alertRed == Color(hex: 0xE5484D))
    }

    @Test func otherPalettesStillResolve() {
        // Ocean maps its own roles onto the Salty slots rather than failing.
        let s = SaltyTokens.resolve(.ocean, dark: false)
        #expect(s.blue == PinchPalette.oceanLight.brand)
        #expect(s.isDark == false)
    }
}
