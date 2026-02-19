import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

public final class LQDeviceInfoMonitor: LQPerfMonitor {
    public var isRunning: Bool = false
    public var onEvent: LQPerfEventHandler?

    #if canImport(UIKit)
    private var pathMonitor: NWPathMonitor?
    private var lastInfo: [String: String] = [:]
    private let sampleInterval: TimeInterval
    private var timer: DispatchSourceTimer?
    #endif

    public init(sampleInterval: TimeInterval = 5) {
        #if canImport(UIKit)
        self.sampleInterval = sampleInterval
        #endif
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(batteryChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryChanged), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(thermalChanged), name: ProcessInfo.thermalStateDidChangeNotification, object: nil)

        #if canImport(Network)
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] _ in
            self?.emitIfChanged()
        }
        monitor.start(queue: DispatchQueue(label: "lqperf.net.path"))
        pathMonitor = monitor
        #endif

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "lqperf.device.sample"))
        timer.schedule(deadline: .now(), repeating: sampleInterval)
        timer.setEventHandler { [weak self] in
            self?.emitIfChanged(force: true)
        }
        timer.resume()
        self.timer = timer

        emitIfChanged(force: true)
        #endif
    }

    public func stop() {
        isRunning = false
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        pathMonitor?.cancel()
        pathMonitor = nil
        timer?.cancel()
        timer = nil
        #endif
    }

    #if canImport(UIKit)
    @objc private func batteryChanged() {
        emitIfChanged()
    }

    @objc private func thermalChanged() {
        emitIfChanged()
    }

    private func emitIfChanged(force: Bool = false) {
        let info = LQSystemInfo.snapshot(networkPath: pathMonitor?.currentPath)
        if force || info != lastInfo {
            lastInfo = info
            onEvent?(LQPerfMetricEvent(type: .device, value: 1.0, info: info, priority: .low))
        }
    }
    #endif
}
