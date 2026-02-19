import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class LQAppLifecycleMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    #if canImport(UIKit)
    private var bgStart: DispatchTime?
    private var fgStart: DispatchTime?
    private var firstFrameLink: CADisplayLink?
    private var firstFrameReported = false
    private let processStartTime: TimeInterval
    #endif

    public init() {
        #if canImport(UIKit)
        self.processStartTime = LQSystemMetrics.processStartTime() ?? Date().timeIntervalSince1970
        #endif
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        #endif
    }

    public func stop() {
        isRunning = false
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        firstFrameLink?.invalidate()
        firstFrameLink = nil
        #endif
    }

    #if canImport(UIKit)
    @objc private func willResignActive() {
        bgStart = DispatchTime.now()
    }

    @objc private func didEnterBackground() {
        guard let start = bgStart else { return }
        let deltaMs = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
        onEvent?(LQPerfMetricEvent(type: .appSwitch, value: deltaMs, info: ["direction": "toBackground"]))
    }

    @objc private func willEnterForeground() {
        fgStart = DispatchTime.now()
    }

    @objc private func didBecomeActive() {
        if let start = fgStart {
            let deltaMs = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
            onEvent?(LQPerfMetricEvent(type: .appSwitch, value: deltaMs, info: ["direction": "toForeground"]))
        }

        if !firstFrameReported {
            firstFrameReported = true
            let link = CADisplayLink(target: self, selector: #selector(firstFrameTick))
            link.add(to: .main, forMode: .common)
            firstFrameLink = link
        }
    }

    @objc private func firstFrameTick() {
        firstFrameLink?.invalidate()
        firstFrameLink = nil
        let durationMs = (Date().timeIntervalSince1970 - processStartTime) * 1000.0
        onEvent?(LQPerfMetricEvent(type: .firstFrame, value: durationMs))
    }
    #endif
}
