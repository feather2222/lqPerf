import Foundation

final class LQNetworkURLProtocol: URLProtocol {
    static var onEvent: ((LQPerfMetricEvent) -> Void)?
    private static let handledKey = "LQNetworkURLProtocolHandled"

    private var dataTask: URLSessionDataTask?
    private var startTime: CFAbsoluteTime = 0
    private var response: URLResponse?
    private var timingInfo: [String: String] = [:]
    private var responseBytes: Int = 0
    private var requestBodyBytes: Int = 0

    override class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: handledKey, in: request) != nil {
            return false
        }
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        startTime = CFAbsoluteTimeGetCurrent()
        responseBytes = 0
        requestBodyBytes = request.httpBody?.count ?? 0

        let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest ?? NSMutableURLRequest(url: request.url ?? URL(string: "about:blank")!)
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        let config = URLSessionConfiguration.default
        if let classes = config.protocolClasses {
            config.protocolClasses = classes.filter { $0 != LQNetworkURLProtocol.self }
        }

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
}

extension LQNetworkURLProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let transaction = metrics.transactionMetrics.first else { return }
        func durationMs(_ start: Date?, _ end: Date?) -> Double? {
            guard let start, let end else { return nil }
            return end.timeIntervalSince(start) * 1000.0
        }

        if let ms = durationMs(transaction.domainLookupStartDate, transaction.domainLookupEndDate) {
            timingInfo["dnsMs"] = String(format: "%.2f", ms)
        }
        if let ms = durationMs(transaction.connectStartDate, transaction.connectEndDate) {
            timingInfo["tcpMs"] = String(format: "%.2f", ms)
        }
        if let ms = durationMs(transaction.secureConnectionStartDate, transaction.secureConnectionEndDate) {
            timingInfo["tlsMs"] = String(format: "%.2f", ms)
        }
        if let ms = durationMs(transaction.requestStartDate, transaction.responseStartDate) {
            timingInfo["ttfbMs"] = String(format: "%.2f", ms)
        }
        if let ms = durationMs(transaction.responseStartDate, transaction.responseEndDate) {
            timingInfo["downloadMs"] = String(format: "%.2f", ms)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseBytes += data.count
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let durationMs = (endTime - startTime) * 1000.0

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }

        var info: [String: String] = [:]
        info["url"] = request.url?.absoluteString ?? ""
        info["method"] = request.httpMethod ?? ""
        info["requestBytes"] = String(requestBodyBytes)
        info["responseBytes"] = String(responseBytes)

        if let http = response as? HTTPURLResponse {
            info["status"] = String(http.statusCode)
        }
        if let error {
            info["error"] = String(describing: error)
        }
        timingInfo.forEach { info[$0.key] = $0.value }

        let event = LQPerfMetricEvent(type: .network, value: durationMs, info: info)
        Self.onEvent?(event)
    }
}
