import Foundation

final class LQPerfCrashStore {
    private let maxCount: Int
    private var buffer: [LQPerfMetricEvent] = []
    private var pending = 0
    private let queue = DispatchQueue(label: "lqperf.crash.store")
    private let url: URL

    init(maxCount: Int) {
        self.maxCount = maxCount
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.url = (dir ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("lqperf-crash-last.json")
    }

    func append(_ event: LQPerfMetricEvent) {
        queue.async {
            self.buffer.append(event)
            if self.buffer.count > self.maxCount {
                self.buffer.removeFirst(self.buffer.count - self.maxCount)
            }
            self.pending += 1
            if self.pending >= 20 {
                self.pending = 0
                self.flush()
            }
        }
    }

    private func flush() {
        let payload: [[String: Any]] = buffer.map { event in
            [
                "type": event.type.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970,
                "value": event.value,
                "info": event.info,
                "priority": event.priority.rawValue
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}
