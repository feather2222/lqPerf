import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class LQReportPlugin: LQPerfPlugin {
    public let id: String
    private let reporter: LQPerfReporter
    private let interval: TimeInterval
    private weak var perf: LQPerf?
    private var timer: DispatchSourceTimer?
    private let store: LQPerfEventStore
    #if canImport(UIKit)
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    #endif

    public init(id: String = "lqperf.report", reporter: LQPerfReporter, interval: TimeInterval = 30, storeURL: URL? = nil) {
        self.id = id
        self.reporter = reporter
        self.interval = interval
        let url = storeURL ?? LQReportPlugin.defaultStoreURL()
        self.store = LQPerfEventStore(fileURL: url)
    }

    public func start(perf: LQPerf) {
        self.perf = perf
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.flush()
        }
        self.timer = timer
        timer.resume()

        #if canImport(UIKit)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #endif
    }

    public func stop() {
        timer?.cancel()
        timer = nil
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        #endif
    }

    private func flush() {
        guard let perf = perf else { return }
        let newEvents = perf.drainEvents()
        let stored = store.drain()
        let batch = stored + newEvents
        guard !batch.isEmpty else { return }

        reporter.report(batch) { [weak self] ok in
            guard let self else { return }
            if !ok {
                self.store.append(batch)
            }
        }
    }

    #if canImport(UIKit)
    @objc private func enteredBackground() {
        if backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "lqperf.report") { [weak self] in
                if let task = self?.backgroundTask {
                    UIApplication.shared.endBackgroundTask(task)
                    self?.backgroundTask = .invalid
                }
            }
        }

        flush()

        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    #endif

    private static func defaultStoreURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (dir ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent("lqperf-report-queue.json")
    }
}
