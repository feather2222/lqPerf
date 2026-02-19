import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public extension Notification.Name {
    static let LQPerfPageWillAppear = Notification.Name("lqperf.page.willAppear")
    static let LQPerfPageDidAppear = Notification.Name("lqperf.page.didAppear")
}

public enum LQPagePerfTracker {
    public static func track(_ viewController: UIViewController) {
        let name = String(describing: type(of: viewController))
        NotificationCenter.default.post(name: .LQPerfPageWillAppear, object: viewController, userInfo: ["page": name])
        NotificationCenter.default.post(name: .LQPerfPageDidAppear, object: viewController, userInfo: ["page": name])
    }
}
#endif
