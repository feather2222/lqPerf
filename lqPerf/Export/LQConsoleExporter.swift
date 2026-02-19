import Foundation

public final class LQConsoleExporter: LQPerfExporter {
    public init() {}

    public func export(_ event: LQPerfMetricEvent) {
        let (formatted, unit) = formatValue(event)
        let infoText = event.info.isEmpty ? "" : " | \(event.info)"
        print("[LQPerf] \(event.type.rawValue) = \(formatted)\(unit)\(infoText)")
    }

    private func formatValue(_ event: LQPerfMetricEvent) -> (String, String) {
        switch event.type {
        case .startup, .firstFrame:
            return (String(format: "%.2f", event.value / 1000.0), " s")
        case .fps:
            return (String(format: "%.2f", event.value), " fps")
        case .memory:
            return (String(format: "%.2f", event.value), " MB")
        case .cpu:
            return (String(format: "%.2f", event.value), " %")
        case .lag, .appSwitch, .pageRender, .pageInteractive, .network:
            return (String(format: "%.2f", event.value), " ms")
        case .device:
            return (String(format: "%.2f", event.value), "")
        }
    }
}
