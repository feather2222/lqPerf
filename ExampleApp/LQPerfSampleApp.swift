import SwiftUI
import lqPerf

@main
struct LQPerfSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    LQPerf.shared.start()
                }
        }
    }
}
