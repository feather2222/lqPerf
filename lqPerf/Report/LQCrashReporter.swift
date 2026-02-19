import Foundation

public protocol LQCrashReporter {
    func reportCrash(data: Data, completion: ((Bool) -> Void)?)
}
