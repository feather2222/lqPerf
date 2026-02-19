import Foundation

public final class LQCPUMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    private var timer: DispatchSourceTimer?

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            if let cpu = LQSystemMetrics.cpuUsagePercent() {
                self.onEvent?(LQPerfMetricEvent(type: .cpu, value: cpu, priority: .low))
            }
        }
        self.timer = timer
        timer.resume()
    }

    public func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }
}
