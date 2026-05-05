import SwiftUI

@main
struct RetirementPlannerApp: App {
    @State private var planStore = PlanStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(planStore)
        }
    }
}
