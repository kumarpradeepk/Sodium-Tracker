import Testing
@testable import Sodium_Tracker

@MainActor
struct FoodLogSessionTests {
    @Test func dismissalClearsSearchAndReopeningStartsFresh() {
        let ui = UIState()
        ui.openFoodLog()
        ui.search = "oatmeal"
        ui.closeFoodLog()
        #expect(ui.search.isEmpty)
        #expect(!ui.logOpen)
        ui.openFoodLog()
        #expect(ui.logOpen)
        #expect(ui.search.isEmpty)
    }

    @Test func successfulAddClearsSearchBeforeNextSession() {
        let ui = UIState()
        ui.openFoodLog()
        ui.search = "toast"
        ui.picked = FoodItem.catalog[0]
        ui.closeAllSheets()
        ui.openFoodLog()
        #expect(ui.search.isEmpty)
        #expect(ui.picked == nil)
        #expect(!ui.qlOpen && !ui.cfOpen && !ui.quickAddOpen)
    }

    @Test func openingResetsStaleQueryButNotAnAlreadyOpenSession() {
        let ui = UIState()
        ui.search = "old search"
        ui.openFoodLog()
        #expect(ui.search.isEmpty)
        ui.search = "current search"
        ui.picked = FoodItem.catalog[0]
        ui.openFoodLog()
        #expect(ui.search == "current search")
        #expect(ui.picked != nil)
        ui.picked = nil
        #expect(ui.search == "current search")
    }
}
