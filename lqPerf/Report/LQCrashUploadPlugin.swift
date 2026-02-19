import Foundation

public final class LQCrashUploadPlugin: LQPerfPlugin {
    public let id: String
    private let reporter: LQCrashReporter
    private let retentionDays: Int
    private let maxFileBytes: Int
    private let maxRetryCount: Int
    private let backoffSeconds: TimeInterval
    private var stats = LQCrashUploadStats()

    public init(
        id: String = "lqperf.crash.upload",
        reporter: LQCrashReporter,
        retentionDays: Int,
        maxFileBytes: Int,
        maxRetryCount: Int = 3,
        backoffSeconds: TimeInterval = 30
    ) {
        self.id = id
        self.reporter = reporter
        self.retentionDays = retentionDays
        self.maxFileBytes = maxFileBytes
        self.maxRetryCount = maxRetryCount
        self.backoffSeconds = backoffSeconds
    }

    public func start(perf: LQPerf) {
        uploadIfNeeded()
    }

    public func stop() {}

    private func uploadIfNeeded() {
        let url = LQCrashTracer.crashEventsURL()
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }

        if shouldDelete(url: url) {
            try? fm.removeItem(at: url)
            return
        }

        guard let data = try? Data(contentsOf: url) else { return }
        let now = Date().timeIntervalSince1970
        if stats.nextAttemptTime > now {
            return
        }

        reporter.reportCrash(data: data) { ok in
            if ok {
                self.stats.successCount += 1
                self.stats.resetRetry()
                try? fm.removeItem(at: url)
            } else {
                self.stats.failureCount += 1
                self.stats.retryCount += 1
                if self.stats.retryCount > self.maxRetryCount {
                    try? fm.removeItem(at: url)
                    self.stats.resetRetry()
                } else {
                    self.stats.nextAttemptTime = Date().timeIntervalSince1970 + self.backoffSeconds
                }
            }
        }
    }

    private func shouldDelete(url: URL) -> Bool {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: url.path) else { return false }
        let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
        if size > maxFileBytes { return true }
        if let modified = attrs[.modificationDate] as? Date {
            let expire = modified.addingTimeInterval(TimeInterval(retentionDays * 24 * 3600))
            if Date() > expire { return true }
        }
        return false
    }
}

private struct LQCrashUploadStats {
    var successCount: Int = 0
    var failureCount: Int = 0
    var retryCount: Int = 0
    var nextAttemptTime: TimeInterval = 0

    mutating func resetRetry() {
        retryCount = 0
        nextAttemptTime = 0
    }
}
