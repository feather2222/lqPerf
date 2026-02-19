import Foundation

public final class LQNetworkMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        LQNetworkURLProtocol.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
        URLProtocol.registerClass(LQNetworkURLProtocol.self)
    }

    public func stop() {
        isRunning = false
        URLProtocol.unregisterClass(LQNetworkURLProtocol.self)
        LQNetworkURLProtocol.onEvent = nil
    }
}
