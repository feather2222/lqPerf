# Getting Started

## 1. 添加源码

将 lqPerf 目录拖入你的工程，并确保加入到目标 Target。

## 2. 启动监控

在 App 启动阶段调用：
- LQPerf.shared.start()

## 3. 自定义配置

可通过 LQPerfConfig 开关模块：
- enableStartup / enableFPS / enableMemory / enableLag / enableCPU / enableNetwork
- enableOverlay

## 4. 导出事件

你可以追加导出器：
- LQPerf.shared.addExporter(LQJSONFileExporter(fileURL: url))
