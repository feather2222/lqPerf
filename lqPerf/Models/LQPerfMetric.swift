import Foundation

public enum LQPerfMetricType: String, CaseIterable {
    case startup
    case fps
    case memory
    case lag
    case cpu
    case network
    case appSwitch
    case firstFrame
    case device
    case pageRender
    case pageInteractive
}

public struct LQPerfMetricEvent {
    public let type: LQPerfMetricType
    public let timestamp: Date
    public let value: Double
    public let info: [String: String]
    public let priority: LQPerfPriority

    public init(type: LQPerfMetricType, value: Double, info: [String: String] = [:], priority: LQPerfPriority = .normal, timestamp: Date = Date()) {
        self.type = type
        self.value = value
        self.info = info
        self.priority = priority
        self.timestamp = timestamp
    }
}
