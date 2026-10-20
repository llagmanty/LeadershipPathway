import SwiftUI

@main
struct LeadershipPathwayApp: App {
    @StateObject private var store = ProgressStore(plan: .bundled)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
