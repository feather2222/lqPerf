import Foundation

public final class LQLagMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    private let thresholdMs: Double
    private let captureStack: Bool
    private let reportMinIntervalMs: Double
    private let mergeSameStackWithinMs: Double
    private var timer: DispatchSourceTimer?
    private var lastPingTime = DispatchTime.now()
    private var lastEmitPingNs: UInt64 = 0
    private var lastReportTime = DispatchTime.now()
    private var lastStackSignature: Int = 0
    private var lastStackReportNs: UInt64 = 0

    public init(thresholdMs: Double, captureStack: Bool, reportMinIntervalMs: Double, mergeSameStackWithinMs: Double) {
        self.thresholdMs = thresholdMs
        self.captureStack = captureStack
        self.reportMinIntervalMs = reportMinIntervalMs
        self.mergeSameStackWithinMs = mergeSameStackWithinMs
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: 0.1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.lastPingTime = DispatchTime.now()
            }

            let now = DispatchTime.now()
            let nowNs = now.uptimeNanoseconds
            let lastNs = self.lastPingTime.uptimeNanoseconds
            guard nowNs >= lastNs else {
                self.lastPingTime = now
                return
            }
            let deltaNs = nowNs - lastNs
            let deltaMs = Double(deltaNs) / 1_000_000.0
            if deltaMs > self.thresholdMs {
                let pingNs = self.lastPingTime.uptimeNanoseconds
                if self.lastEmitPingNs == pingNs {
                    return
                }

                let minIntervalNs = UInt64(self.reportMinIntervalMs * 1_000_000.0)
                if now.uptimeNanoseconds - self.lastReportTime.uptimeNanoseconds < minIntervalNs {
                    return
                }

                self.lastEmitPingNs = pingNs
                self.lastReportTime = now

                if self.captureStack {
                    DispatchQueue.main.async {
                        let stackArray = LQBacktrace.current()
                        let stack = stackArray.joined(separator: "\n")
                        let signature = stack.hashValue
                        let mergeWindowNs = UInt64(self.mergeSameStackWithinMs * 1_000_000.0)
                        let nowNs = DispatchTime.now().uptimeNanoseconds

                        if signature == self.lastStackSignature,
                           nowNs - self.lastStackReportNs < mergeWindowNs {
                            return
                        }

                        self.lastStackSignature = signature
                        self.lastStackReportNs = nowNs

                        self.onEvent?(LQPerfMetricEvent(
                            type: .lag,
                            value: deltaMs,
                            info: [
                                "thresholdMs": String(self.thresholdMs),
                                "stack": stack
                            ]
                        ))
                    }
                } else {
                    self.onEvent?(LQPerfMetricEvent(type: .lag, value: deltaMs, info: ["thresholdMs": String(self.thresholdMs)]))
                }
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
