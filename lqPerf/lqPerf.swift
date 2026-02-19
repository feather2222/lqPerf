//
//  lqPerf.swift
//  lqPerf
//
//  Created by xiangduojia on 2026/2/17.
//

import Foundation

public final class LQPerf {
	public static let shared = LQPerf()

	private var monitors: [LQPerfMonitor] = []
	private var exporters: [LQPerfExporter] = []
	private var handlers: [UUID: LQPerfEventHandler] = [:]
	private let recorder = LQPerfRecorder(maxCount: 200)
	private var crashStore: LQPerfCrashStore?
	private var rateLimiter: LQPerfRateLimiter?
	private var plugins: [String: LQPerfPlugin] = [:]
	private var isRunning = false

	private init() {}

	public func start(config: LQPerfConfig = .default) {
		guard !isRunning else { return }
		isRunning = true

		exporters = config.exporters
		if config.crashAutoPersist {
			crashStore = LQPerfCrashStore(maxCount: config.crashPersistMaxCount)
		} else {
			crashStore = nil
		}
		LQCrashTracer.install()
		if let reporter = config.crashAutoUploadReporter {
			register(plugin: LQCrashUploadPlugin(
				reporter: reporter,
				retentionDays: config.crashRetentionDays,
				maxFileBytes: config.crashMaxFileBytes,
				maxRetryCount: config.crashUploadMaxRetryCount,
				backoffSeconds: config.crashUploadBackoffSeconds
			))
		}
		if config.enableRateLimit {
			rateLimiter = LQPerfRateLimiter(windowMs: config.rateLimitWindowMs, maxCount: config.rateLimitMaxCount)
		} else {
			rateLimiter = nil
		}
		monitors = LQPerfFactory.makeMonitors(config: config, emit: { [weak self] event in
			self?.emit(event)
		})

		config.plugins.forEach { register(plugin: $0) }

		if config.enableOverlay {
			LQPerfOverlayController.shared.start()
		}

		monitors.forEach { $0.start() }
		plugins.values.forEach { $0.start(perf: self) }
	}

	public func stop() {
		guard isRunning else { return }
		isRunning = false
		monitors.forEach { $0.stop() }
		monitors.removeAll()
		plugins.values.forEach { $0.stop() }
		plugins.removeAll()
		crashStore = nil
		rateLimiter = nil
		LQPerfOverlayController.shared.stop()
	}

	public func addExporter(_ exporter: LQPerfExporter) {
		exporters.append(exporter)
	}

	@discardableResult
	public func addEventHandler(_ handler: @escaping LQPerfEventHandler) -> UUID {
		let id = UUID()
		handlers[id] = handler
		return id
	}

	public func removeEventHandler(_ id: UUID) {
		handlers.removeValue(forKey: id)
	}

	public func register(plugin: LQPerfPlugin) {
		plugins[plugin.id] = plugin
		if isRunning {
			plugin.start(perf: self)
		}
	}

	public func unregisterPlugin(id: String) {
		if let plugin = plugins.removeValue(forKey: id) {
			plugin.stop()
		}
	}

	public func recentEvents() -> [LQPerfMetricEvent] {
		recorder.all()
	}

	public func drainEvents() -> [LQPerfMetricEvent] {
		recorder.drain()
	}

	@discardableResult
	public func exportRecentEvents(to url: URL) -> Bool {
		let events = recorder.all()
		return LQPerfEventSerializer.write(events: events, to: url)
	}

	private func emit(_ event: LQPerfMetricEvent) {
		if event.priority == .low, let limiter = rateLimiter, !limiter.allow(event.type) {
			return
		}
		recorder.append(event)
		crashStore?.append(event)
		exporters.forEach { $0.export(event) }
		handlers.values.forEach { $0(event) }
	}
}

