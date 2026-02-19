import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif

enum LQSystemInfo {
    #if canImport(UIKit)
    static func snapshot(networkPath: NWPath?) -> [String: String] {
        var info: [String: String] = [:]
        let device = UIDevice.current

        info["os"] = device.systemName
        info["osVersion"] = device.systemVersion
        info["deviceModel"] = deviceModel()
        info["batteryLevel"] = String(format: "%.2f", device.batteryLevel)
        info["batteryState"] = batteryState(device.batteryState)
        info["thermalState"] = thermalState(ProcessInfo.processInfo.thermalState)

        if let (total, free) = diskSpace() {
            info["diskTotalGB"] = String(format: "%.2f", total)
            info["diskFreeGB"] = String(format: "%.2f", free)
        }

        if let path = networkPath {
            info["network"] = networkType(path)
            info["networkExpensive"] = path.isExpensive ? "true" : "false"
        }

        return info
    }
    #else
    static func snapshot(networkPath: Any? = nil) -> [String: String] {
        return [:]
    }
    #endif

    #if canImport(UIKit)
    private static func batteryState(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging: return "charging"
        case .full: return "full"
        case .unplugged: return "unplugged"
        default: return "unknown"
        }
    }

    private static func thermalState(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    private static func diskSpace() -> (Double, Double)? {
        let fm = FileManager.default
        guard let path = fm.urls(for: .documentDirectory, in: .userDomainMask).first?.path else { return nil }
        guard let attrs = try? fm.attributesOfFileSystem(forPath: path),
              let total = attrs[.systemSize] as? NSNumber,
              let free = attrs[.systemFreeSize] as? NSNumber else { return nil }
        let totalGB = total.doubleValue / 1024 / 1024 / 1024
        let freeGB = free.doubleValue / 1024 / 1024 / 1024
        return (totalGB, freeGB)
    }

    private static func deviceModel() -> String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    #if canImport(Network)
    private static func networkType(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        if path.usesInterfaceType(.wiredEthernet) { return "ethernet" }
        if path.usesInterfaceType(.loopback) { return "loopback" }
        return "other"
    }
    #else
    private static func networkType(_ path: Any) -> String { "unknown" }
    #endif
    #endif
}
