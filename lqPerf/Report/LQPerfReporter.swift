import Foundation

public protocol LQPerfReporter {
    func report(_ events: [LQPerfMetricEvent], completion: ((Bool) -> Void)?)
}
