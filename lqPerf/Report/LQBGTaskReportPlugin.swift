import Foundation
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

public final class LQBGTaskReportPlugin: LQPerfPlugin {
    public let id: String
    private let taskIdentifier: String
    private let reporter: LQPerfReporter
    private let interval: TimeInterval
    private weak var perf: LQPerf?

    public init(id: String = "lqperf.bg.report", taskIdentifier: String, reporter: LQPerfReporter, interval: TimeInterval = 30 * 60) {
        self.id = id
        self.taskIdentifier = taskIdentifier
        self.reporter = reporter
        self.interval = interval
    }

    public func start(perf: LQPerf) {
        self.perf = perf
        #if canImport(BackgroundTasks)
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { [weak self] task in
                self?.handle(task: task)
            }
            schedule()
        }
        #endif
    }

    public func stop() {}

    #if canImport(BackgroundTasks)
    @available(iOS 13.0, *)
    private func handle(task: BGTask) {
        schedule()

        task.expirationHandler = { [weak task] in
            task?.setTaskCompleted(success: false)
        }

        guard let perf else {
            task.setTaskCompleted(success: true)
            return
        }

        let events = perf.drainEvents()
        reporter.report(events) { ok in
            task.setTaskCompleted(success: ok)
        }
    }

    @available(iOS 13.0, *)
    private func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[LQPerf] BGTask submit failed: \(error)")
        }
    }
    #endif
}
