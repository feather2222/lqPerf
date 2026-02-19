import Foundation

public protocol LQPerfPlugin: AnyObject {
    var id: String { get }
    func start(perf: LQPerf)
    func stop()
}
