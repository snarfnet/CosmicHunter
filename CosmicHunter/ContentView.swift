import SwiftUI

struct ContentView: View {
    @StateObject private var detector = CosmicDetector()
    @StateObject private var store = HitStore()
    @StateObject private var altitude = AltitudeService()
    @State private var selection = 0

    static var screenshotMode: Int? {
        for arg in CommandLine.arguments {
            if arg.hasPrefix("SCREENSHOT_MODE_"), let n = Int(arg.dropFirst("SCREENSHOT_MODE_".count)) {
                return n
            }
        }
        return nil
    }

    var body: some View {
        TabView(selection: $selection) {
            ObserveScreen(detector: detector, store: store, altitude: altitude)
                .tabItem { Label(L("観測", "Observe"), systemImage: "dot.radiowaves.left.and.right") }
                .tag(0)
            RecordsView(store: store)
                .tabItem { Label(L("記録", "Records"), systemImage: "star.circle") }
                .tag(1)
            GuideView()
                .tabItem { Label(L("使い方", "Guide"), systemImage: "book") }
                .tag(2)
            InfoView()
                .tabItem { Label(L("情報", "Info"), systemImage: "info.circle") }
                .tag(3)
        }
        .tint(Retro.lcd)
        .preferredColorScheme(.dark)
        .onAppear {
            if let mode = Self.screenshotMode {
                detector.loadDemoState()
                store.loadDemoState()
                altitude.loadDemoState()
                selection = min(max(mode - 1, 0), 3)
            }
        }
    }
}
