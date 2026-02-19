import Foundation

final class LQPerfEventStore {
    private let url: URL
    private let queue = DispatchQueue(label: "lqperf.event.store")

    init(fileURL: URL) {
        self.url = fileURL
    }

    func append(_ events: [LQPerfMetricEvent]) {
        guard !events.isEmpty else { return }
        queue.sync {
            var current = load()
            current.append(contentsOf: events)
            save(current)
        }
    }

    func drain() -> [LQPerfMetricEvent] {
        queue.sync {
            let current = load()
            save([])
            return current
        }
    }

    private func load() -> [LQPerfMetricEvent] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []), let array = json as? [[String: Any]] else { return [] }
        return array.compactMap { dict in
            guard let typeRaw = dict["type"] as? String,
                  let type = LQPerfMetricType(rawValue: typeRaw),
                  let timestamp = dict["timestamp"] as? TimeInterval,
                  let value = dict["value"] as? Double else { return nil }
            let info = dict["info"] as? [String: String] ?? [:]
            let priorityRaw = dict["priority"] as? String
            let priority = LQPerfPriority(rawValue: priorityRaw ?? "normal") ?? .normal
            return LQPerfMetricEvent(type: type, value: value, info: info, priority: priority, timestamp: Date(timeIntervalSince1970: timestamp))
        }
    }

    private func save(_ events: [LQPerfMetricEvent]) {
        let payload: [[String: Any]] = events.map { event in
            [
                "type": event.type.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970,
                "value": event.value,
                "info": event.info,
                "priority": event.priority.rawValue
            ]
        }
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            try? data.write(to: url, options: [.atomic])
        }
    }
}
