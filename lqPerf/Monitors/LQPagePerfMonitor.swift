import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class LQPagePerfMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    #if canImport(UIKit)
    private var isTracking = false
    private var startTime = DispatchTime.now()
    #endif

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        #if canImport(UIKit)
        LQPagePerfAutoTracker.install()
        NotificationCenter.default.addObserver(self, selector: #selector(pageWillAppear), name: .LQPerfPageWillAppear, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pageDidAppear), name: .LQPerfPageDidAppear, object: nil)
        #endif
    }

    public func stop() {
        isRunning = false
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        #endif
    }

    #if canImport(UIKit)
    @objc private func pageWillAppear(_ note: Notification) {
        isTracking = true
        startTime = DispatchTime.now()
    }

    @objc private func pageDidAppear(_ note: Notification) {
        guard isTracking else { return }
        isTracking = false
        let durationMs = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
        let pageName = (note.userInfo?["page"] as? String) ?? "unknown"
        onEvent?(LQPerfMetricEvent(type: .pageRender, value: durationMs, info: ["page": pageName]))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            self.onEvent?(LQPerfMetricEvent(type: .pageInteractive, value: durationMs, info: ["page": pageName]))
        }
    }
    #endif
}
