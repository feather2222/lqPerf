import Foundation

public struct LQPerfConfig {
    public var enableStartup: Bool
    public var enableFPS: Bool
    public var enableMemory: Bool
    public var enableLag: Bool
    public var enableCPU: Bool
    public var enableNetwork: Bool
    public var enableAppLifecycle: Bool
    public var enableDeviceInfo: Bool
    public var deviceSampleInterval: TimeInterval
    public var enablePagePerf: Bool
    public var enableOverlay: Bool
    public var lagThresholdMs: Double
    public var lagCaptureStack: Bool
    public var lagReportMinIntervalMs: Double
    public var lagMergeSameStackWithinMs: Double
    public var crashAutoPersist: Bool
    public var crashPersistMaxCount: Int
    public var crashAutoUploadReporter: LQCrashReporter?
    public var crashRetentionDays: Int
    public var crashMaxFileBytes: Int
    public var crashUploadMaxRetryCount: Int
    public var crashUploadBackoffSeconds: TimeInterval
    public var enableRateLimit: Bool
    public var rateLimitWindowMs: Double
    public var rateLimitMaxCount: Int
    public var exporters: [LQPerfExporter]
    public var plugins: [LQPerfPlugin]

    public init(
        enableStartup: Bool = true,
        enableFPS: Bool = true,
        enableMemory: Bool = true,
        enableLag: Bool = true,
        enableCPU: Bool = true,
        enableNetwork: Bool = false,
        enableAppLifecycle: Bool = true,
        enableDeviceInfo: Bool = true,
        deviceSampleInterval: TimeInterval = 5,
        enablePagePerf: Bool = true,
        enableOverlay: Bool = true,
        lagThresholdMs: Double = 120.0,
        lagCaptureStack: Bool = true,
        lagReportMinIntervalMs: Double = 500.0,
        lagMergeSameStackWithinMs: Double = 3000.0,
        crashAutoPersist: Bool = true,
        crashPersistMaxCount: Int = 200,
        crashAutoUploadReporter: LQCrashReporter? = nil,
        crashRetentionDays: Int = 7,
        crashMaxFileBytes: Int = 512 * 1024,
        crashUploadMaxRetryCount: Int = 3,
        crashUploadBackoffSeconds: TimeInterval = 30,
        enableRateLimit: Bool = true,
        rateLimitWindowMs: Double = 1000,
        rateLimitMaxCount: Int = 10,
        exporters: [LQPerfExporter] = [LQConsoleExporter()],
        plugins: [LQPerfPlugin] = []
    ) {
        self.enableStartup = enableStartup
        self.enableFPS = enableFPS
        self.enableMemory = enableMemory
        self.enableLag = enableLag
        self.enableCPU = enableCPU
        self.enableNetwork = enableNetwork
        self.enableAppLifecycle = enableAppLifecycle
        self.enableDeviceInfo = enableDeviceInfo
        self.deviceSampleInterval = deviceSampleInterval
        self.enablePagePerf = enablePagePerf
        self.enableOverlay = enableOverlay
        self.lagThresholdMs = lagThresholdMs
        self.lagCaptureStack = lagCaptureStack
        self.lagReportMinIntervalMs = lagReportMinIntervalMs
        self.lagMergeSameStackWithinMs = lagMergeSameStackWithinMs
        self.crashAutoPersist = crashAutoPersist
        self.crashPersistMaxCount = crashPersistMaxCount
        self.crashAutoUploadReporter = crashAutoUploadReporter
        self.crashRetentionDays = crashRetentionDays
        self.crashMaxFileBytes = crashMaxFileBytes
        self.crashUploadMaxRetryCount = crashUploadMaxRetryCount
        self.crashUploadBackoffSeconds = crashUploadBackoffSeconds
        self.enableRateLimit = enableRateLimit
        self.rateLimitWindowMs = rateLimitWindowMs
        self.rateLimitMaxCount = rateLimitMaxCount
        self.exporters = exporters
        self.plugins = plugins
    }

    public static let `default` = LQPerfConfig()
}

public enum LQPerfFactory {
    public static func makeMonitors(
        config: LQPerfConfig,
        emit: @escaping LQPerfEventHandler
    ) -> [LQPerfMonitor] {
        var list: [LQPerfMonitor] = []

        if config.enableStartup {
            let monitor = LQStartupMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableFPS {
            let monitor = LQFPSMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableMemory {
            let monitor = LQMemoryMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableLag {
            let monitor = LQLagMonitor(
                thresholdMs: config.lagThresholdMs,
                captureStack: config.lagCaptureStack,
                reportMinIntervalMs: config.lagReportMinIntervalMs,
                mergeSameStackWithinMs: config.lagMergeSameStackWithinMs
            )
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableCPU {
            let monitor = LQCPUMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableNetwork {
            let monitor = LQNetworkMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableAppLifecycle {
            let monitor = LQAppLifecycleMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enableDeviceInfo {
            let monitor = LQDeviceInfoMonitor(sampleInterval: config.deviceSampleInterval)
            monitor.onEvent = emit
            list.append(monitor)
        }

        if config.enablePagePerf {
            let monitor = LQPagePerfMonitor()
            monitor.onEvent = emit
            list.append(monitor)
        }

        return list
    }
}
