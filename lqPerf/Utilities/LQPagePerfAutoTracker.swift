import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime
#endif

#if canImport(UIKit)
final class LQPagePerfAutoTracker {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true

        swizzle(
            UIViewController.self,
            #selector(UIViewController.viewWillAppear(_:)),
            #selector(UIViewController.lqperf_viewWillAppear(_:))
        )

        swizzle(
            UIViewController.self,
            #selector(UIViewController.viewDidAppear(_:)),
            #selector(UIViewController.lqperf_viewDidAppear(_:))
        )
    }

    private static func swizzle(_ cls: AnyClass, _ original: Selector, _ replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let replacementMethod = class_getInstanceMethod(cls, replacement) else {
            return
        }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }
}

extension UIViewController {
    @objc func lqperf_viewWillAppear(_ animated: Bool) {
        self.lqperf_viewWillAppear(animated)
        let name = String(describing: type(of: self))
        NotificationCenter.default.post(name: .LQPerfPageWillAppear, object: self, userInfo: ["page": name])
    }

    @objc func lqperf_viewDidAppear(_ animated: Bool) {
        self.lqperf_viewDidAppear(animated)
        let name = String(describing: type(of: self))
        NotificationCenter.default.post(name: .LQPerfPageDidAppear, object: self, userInfo: ["page": name])
    }
}
#endif
