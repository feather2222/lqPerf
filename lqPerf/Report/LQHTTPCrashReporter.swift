import Foundation

public final class LQHTTPCrashReporter: LQCrashReporter {
    private let endpoint: URL
    private let session: URLSession

    public init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    public func reportCrash(data: Data, completion: ((Bool) -> Void)?) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let task = session.dataTask(with: request) { _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let ok = (error == nil) && (200..<300).contains(status)
            completion?(ok)
        }
        task.resume()
    }
}
