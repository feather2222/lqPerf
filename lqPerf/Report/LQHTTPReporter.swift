import Foundation

public final class LQHTTPReporter: LQPerfReporter {
    private let endpoint: URL
    private let session: URLSession

    public init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    public func report(_ events: [LQPerfMetricEvent], completion: ((Bool) -> Void)?) {
        guard !events.isEmpty else {
            completion?(true)
            return
        }

        let payload: [[String: Any]] = events.map { event in
            [
                "type": event.type.rawValue,
                "timestamp": event.timestamp.timeIntervalSince1970,
                "value": event.value,
                "info": event.info
            ]
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let task = session.dataTask(with: request) { _, response, error in
                let ok = (error == nil) && (response as? HTTPURLResponse)?.statusCode ?? 0 >= 200
                completion?(ok)
            }
            task.resume()
        } catch {
            completion?(false)
        }
    }
}
