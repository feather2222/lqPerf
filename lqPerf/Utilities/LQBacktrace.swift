import Foundation

enum LQBacktrace {
    static func current() -> [String] {
        return Thread.callStackSymbols
    }
}
