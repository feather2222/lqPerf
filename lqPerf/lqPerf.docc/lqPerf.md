# ``lqPerf``

轻量级 iOS 性能监控 SDK（第一版框架）。

## Overview

覆盖启动耗时、FPS、内存、卡顿、CPU 等基础指标，并支持悬浮面板与导出器。

## Topics

### 核心入口

- ``LQPerf``
- ``LQPerfConfig``

### 监控模块

- ``LQStartupMonitor``
- ``LQFPSMonitor``
- ``LQMemoryMonitor``
- ``LQLagMonitor``
- ``LQCPUMonitor``
- ``LQNetworkMonitor``

### 数据与导出

- ``LQPerfMetricEvent``
- ``LQPerfExporter``
- ``LQConsoleExporter``
- ``LQJSONFileExporter``