import Foundation

public protocol LQPerfExporter {
    func export(_ event: LQPerfMetricEvent)
}
