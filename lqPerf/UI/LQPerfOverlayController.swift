import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class LQPerfOverlayController {
    public static let shared = LQPerfOverlayController()

    #if canImport(UIKit)
    private var window: UIWindow?
    private var label: UILabel?
    private var observerId: UUID?
    private var latest: [LQPerfMetricType: Double] = [:]
    private var isPresenting = false
    #endif

    private init() {}

    #if canImport(UIKit)
    private final class LQPerfOverlayWindow: UIWindow {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            return bounds.contains(point)
        }
    }
    #endif

    public func start() {
        #if canImport(UIKit)
        guard window == nil else { return }

        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) {
                let window = LQPerfOverlayWindow(windowScene: scene)
                window.frame = CGRect(x: 12, y: 60, width: 200, height: 100)

                window.windowLevel = .statusBar + 1
                window.backgroundColor = .clear
                window.layer.cornerRadius = 10
                window.isUserInteractionEnabled = true

                let root = UIViewController()
                root.view.frame = window.bounds
                root.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
                root.view.layer.cornerRadius = 10
                root.view.clipsToBounds = true
                root.view.isUserInteractionEnabled = true
                window.rootViewController = root
                window.isHidden = false

                let label = UILabel(frame: root.view.bounds.insetBy(dx: 8, dy: 8))
                label.numberOfLines = 0
                label.textColor = .white
                label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
                label.isUserInteractionEnabled = false
                root.view.addSubview(label)

                let button = UIButton(type: .custom)
                button.frame = root.view.bounds
                button.backgroundColor = .clear
                button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
                root.view.addSubview(button)

                self.window = window
                self.label = label
            } else {
                return
            }
        } else {
            // iOS 12 及以下不支持悬浮窗
            return
        }

        observerId = LQPerf.shared.addEventHandler { [weak self] event in
            DispatchQueue.main.async {
                self?.latest[event.type] = event.value
                self?.render()
            }
        }
        #endif
    }

    public func stop() {
        #if canImport(UIKit)
        if let id = observerId {
            LQPerf.shared.removeEventHandler(id)
        }
        observerId = nil
        window?.isHidden = true
        window = nil
        label = nil
        latest.removeAll()
        #endif
    }

    #if canImport(UIKit)
    private func render() {
        let fps = format(latest[.fps])
        let mem = format(latest[.memory])
        let cpu = format(latest[.cpu])
        let lag = format(latest[.lag])
        let dev = latest[.device] == nil ? "--" : "OK"
        label?.text = "FPS: \(fps)\nMEM: \(mem) MB\nCPU: \(cpu)%\nLAG: \(lag) ms\nDEV: \(dev)"
    }

    @objc private func handleTap() {
        // 面板功能已移除，仅保留悬浮窗显示
    }

    private func topMostViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            let windows = scene?.windows ?? UIApplication.shared.windows
            let appWindow = windows.first(where: { $0.isKeyWindow && $0.windowLevel == .normal })
                ?? windows.first(where: { $0.windowLevel == .normal })
            var top = appWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        } else {
            let windows = UIApplication.shared.windows
            let appWindow = windows.first(where: { $0.isKeyWindow && $0.windowLevel == .normal })
                ?? windows.first(where: { $0.windowLevel == .normal })
            var top = appWindow?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value)
    }
    #endif
}
