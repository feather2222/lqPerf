# LQPerf

轻量级 iOS 性能监控 SDK。

## 功能

- 启动耗时监控
- FPS/CPU/内存采样
- 卡顿监控（主线程）+ 堆栈采样
- 网络耗时监控（URLSession）+ 分段耗时（DNS/TCP/TLS/TTFB/下载）
- 生命周期指标（前后台切换耗时、首帧渲染耗时）
- 网络请求体/响应体大小统计
- 设备 & 环境信息（OS/机型/电量/温度/磁盘/网络类型）
- 设备信息定时采样（电量/温度变化曲线）
- 页面级性能（渲染/可交互）
- 事件分级与限流（高频指标降噪）
- 崩溃前最后 N 条事件自动落盘
- 崩溃联动（崩溃时自动附带最近事件）
- 悬浮窗显示（无面板）
- 日志导出（控制台 / JSON）
- 上报接口（Reporter）+ 插件化（Plugin）

## 目录结构

- lqPerf/Core: 框架入口与配置
- lqPerf/Models: 事件模型
- lqPerf/Monitors: 性能采集模块
- lqPerf/Export: 导出器
- lqPerf/UI: 悬浮窗
- lqPerf/Utilities: 系统指标工具
- lqPerf/Report: 上报与落盘
- ExampleApp: 示例 App

## 快速集成

1. 将 lqPerf 目录加入到工程，并确保加入目标 Target。
2. 在 App 启动时调用：
   - LQPerf.shared.start()
3. 如需自定义：
   - LQPerfConfig(enableNetwork: true, enableOverlay: true, lagCaptureStack: true, enablePagePerf: true, deviceSampleInterval: 5)

## 全量配置示例

- LQPerfConfig(
  enableStartup: true,
  enableFPS: true,
  enableMemory: true,
  enableLag: true,
  enableCPU: true,
  enableNetwork: true,
  enableAppLifecycle: true,
  enableDeviceInfo: true,
  deviceSampleInterval: 5,
  enablePagePerf: true,
  enableOverlay: true,
  crashAutoPersist: true,
  crashPersistMaxCount: 200,
  enableRateLimit: true,
  rateLimitWindowMs: 1000,
  rateLimitMaxCount: 10
)

## 事件导出

- 默认输出到控制台。
- 可追加 JSON 导出：
  - LQPerf.shared.addExporter(LQJSONFileExporter(fileURL: url))

## 上报接口 + 插件化

示例：每 30 秒批量上报一次

1) 创建 reporter
- LQHTTPReporter(endpoint: url)

2) 注册插件
- LQPerf.shared.start(config: LQPerfConfig(plugins: [
   LQReportPlugin(reporter: LQHTTPReporter(endpoint: url), interval: 30)
]))

## BGTask 后台上报

1) Info.plist 增加 BGTaskSchedulerPermittedIdentifiers
- 例：com.yourcompany.lqperf.report

2) 注册插件（iOS 13+）
- LQPerf.shared.start(config: LQPerfConfig(plugins: [
   LQBGTaskReportPlugin(
     taskIdentifier: "com.yourcompany.lqperf.report",
     reporter: LQHTTPReporter(endpoint: url),
     interval: 30 * 60
   )
]))

## 卡顿降噪（可选）

- lagReportMinIntervalMs: 卡顿上报最小间隔
- lagMergeSameStackWithinMs: 相同堆栈合并窗口

## 事件分级与限流（可选）

- enableRateLimit: 是否开启限流
- rateLimitWindowMs: 窗口大小
- rateLimitMaxCount: 窗口内最大事件数

## 离线上报 + 失败重试 + 后台触发

- 上报失败会落盘（Caches/lqperf-report-queue.json），下次重试自动合并上报
- App 进入后台会触发一次上报（系统允许的后台时间内完成）

## 崩溃前事件自动落盘

- 默认开启：crashAutoPersist = true
- 文件位置：Caches/lqperf-crash-last.json
- 默认保留 200 条（crashPersistMaxCount 可配置）

## 崩溃联动（附带最近事件）

- 文件位置：Caches/lqperf-crash-events.json

## Crash 文件自动上报与清理策略

- 自动上报：
   - LQPerfConfig(crashAutoUploadReporter: LQHTTPCrashReporter(endpoint: url))
- 清理策略：
   - crashRetentionDays: Int（默认 7 天）
   - crashMaxFileBytes: Int（默认 512KB）
- 重试策略：
   - crashUploadMaxRetryCount: Int（默认 3）
   - crashUploadBackoffSeconds: TimeInterval（默认 30s）

## 页面级性能

- 自动追踪：默认开启（基于 UIViewController 生命周期自动上报）
- 手动追踪：LQPagePerfTracker.track(yourViewController)

## 文档

- 主要文档在 lqPerf.docc。
- 示例 App 在 ExampleApp。
