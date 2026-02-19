import Foundation

public typealias LQPerfEventHandler = (LQPerfMetricEvent) -> Void

public protocol LQPerfMonitor: AnyObject {
    var isRunning: Bool { get }
    var onEvent: LQPerfEventHandler? { get set }
    func start()
    func stop()
}
