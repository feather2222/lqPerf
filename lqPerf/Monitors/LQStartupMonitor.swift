import Foundation

public final class LQStartupMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    private let processStartTime: TimeInterval

    public init() {
        self.processStartTime = LQSystemMetrics.processStartTime() ?? Date().timeIntervalSince1970
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        let durationMs = (Date().timeIntervalSince1970 - processStartTime) * 1000.0
        onEvent?(LQPerfMetricEvent(type: .startup, value: durationMs))
    }

    public func stop() {
        isRunning = false
    }
}
