import Foundation

enum LQCrashTracer {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        NSSetUncaughtExceptionHandler { exception in
            let info: [String: Any] = [
                "name": exception.name.rawValue,
                "reason": exception.reason ?? "",
                "stack": exception.callStackSymbols.joined(separator: "\n")
            ]

            let events = LQPerf.shared.recentEvents()
            let eventPayload: [[String: Any]] = events.map { event in
                [
                    "type": event.type.rawValue,
                    "timestamp": event.timestamp.timeIntervalSince1970,
                    "value": event.value,
                    "info": event.info,
                    "priority": event.priority.rawValue
                ]
            }

            let payload: [String: Any] = [
                "crash": info,
                "events": eventPayload
            ]

            if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) {
                try? data.write(to: LQCrashTracer.crashEventsURL(), options: [.atomic])
            }
        }
    }

    static func crashEventsURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (dir ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("lqperf-crash-events.json")
    }
}
