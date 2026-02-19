import Foundation

public final class LQJSONFileExporter: LQPerfExporter {
    private let url: URL
    private let queue = DispatchQueue(label: "lqperf.json.exporter")
    private var buffer: [[String: Any]] = []

    public init(fileURL: URL) {
        self.url = fileURL
    }

    public func export(_ event: LQPerfMetricEvent) {
        queue.async { [weak self] in
            guard let self else { return }
            let item: [String: Any] = [
                "type": event.type.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970,
                "value": event.value,
                "info": event.info,
                "priority": event.priority.rawValue
            ]
            self.buffer.append(item)
            if self.buffer.count >= 50 {
                self.flush()
            }
        }
    }

    public func flush() {
        let payload = buffer
        buffer.removeAll()
        guard !payload.isEmpty else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[LQPerf] JSON export failed: \(error)")
        }
    }
}
