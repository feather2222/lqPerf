import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class LQFPSMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    #if canImport(UIKit)
    private var link: CADisplayLink?
    private var lastTime: TimeInterval = 0
    private var frameCount: Int = 0
    #endif

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        #if canImport(UIKit)
        lastTime = 0
        frameCount = 0
        let link = CADisplayLink(target: self, selector: #selector(tick(link:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        #endif
    }

    public func stop() {
        isRunning = false
        #if canImport(UIKit)
        link?.invalidate()
        link = nil
        #endif
    }

    #if canImport(UIKit)
    @objc private func tick(link: CADisplayLink) {
        if lastTime == 0 {
            lastTime = link.timestamp
            return
        }

        frameCount += 1
        let delta = link.timestamp - lastTime
        if delta >= 1 {
            let fps = Double(frameCount) / delta
            onEvent?(LQPerfMetricEvent(type: .fps, value: fps, priority: .low))
            frameCount = 0
            lastTime = link.timestamp
        }
    }
    #endif
}
