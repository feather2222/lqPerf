import Foundation

final class LQPerfRecorder {
    private let maxCount: Int
    private var buffer: [LQPerfMetricEvent] = []
    private let queue = DispatchQueue(label: "lqperf.recorder")

    init(maxCount: Int) {
        self.maxCount = maxCount
    }

    func append(_ event: LQPerfMetricEvent) {
        queue.async {
            self.buffer.append(event)
            if self.buffer.count > self.maxCount {
                self.buffer.removeFirst(self.buffer.count - self.maxCount)
            }
        }
    }

    func all() -> [LQPerfMetricEvent] {
        queue.sync { buffer }
    }

    func drain() -> [LQPerfMetricEvent] {
        queue.sync {
            let snapshot = buffer
            buffer.removeAll()
            return snapshot
        }
    }
}
