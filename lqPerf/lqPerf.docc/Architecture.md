# Architecture

## 模块

- Core: 配置与入口
- Monitors: 采集模块
- Export: 事件导出
- UI: 监控面板
- Utilities: 系统指标

## 数据流

Monitor -> MetricEvent -> Exporter / Overlay
