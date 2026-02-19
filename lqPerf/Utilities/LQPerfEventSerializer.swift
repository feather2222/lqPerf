import Foundation

enum LQPerfEventSerializer {
    static func write(events: [LQPerfMetricEvent], to url: URL) -> Bool {
        let payload: [[String: Any]] = events.map { event in
            [
                "type": event.type.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970,
                "value": event.value,
                "info": event.info,
                "priority": event.priority.rawValue
            ]
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            try data.write(to: url, options: [.atomic])
            return true
        } catch {
            print("[LQPerf] export failed: \(error)")
            return false
        }
    }
}
