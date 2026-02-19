import Foundation

final class LQPerfRateLimiter {
    private let windowMs: Double
    private let maxCount: Int
    private var counts: [LQPerfMetricType: (count: Int, windowStart: DispatchTime)] = [:]
    private let queue = DispatchQueue(label: "lqperf.ratelimit")

    init(windowMs: Double, maxCount: Int) {
        self.windowMs = windowMs
        self.maxCount = maxCount
    }

    func allow(_ type: LQPerfMetricType) -> Bool {
        let now = DispatchTime.now()
        let windowNs = UInt64(windowMs * 1_000_000.0)
        return queue.sync {
            let entry = counts[type]
            if let entry {
                let nowNs = now.uptimeNanoseconds
                let startNs = entry.windowStart.uptimeNanoseconds
                guard nowNs >= startNs else {
                    counts[type] = (1, now)
                    return true
                }
                let elapsed = nowNs - startNs
                if elapsed > windowNs {
                    counts[type] = (1, now)
                    return true
                }
                if entry.count >= maxCount {
                    return false
                }
                counts[type] = (entry.count + 1, entry.windowStart)
                return true
            } else {
                counts[type] = (1, now)
                return true
            }
        }
    }
}
