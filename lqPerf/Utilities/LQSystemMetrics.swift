import Foundation

#if canImport(Darwin)
import Darwin
#endif

enum LQSystemMetrics {
    static func processStartTime() -> TimeInterval? {
        #if canImport(Darwin)
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = mib.withUnsafeMutableBufferPointer { buffer in
            sysctl(buffer.baseAddress, u_int(buffer.count), &info, &size, nil, 0)
        }
        guard result == 0 else { return nil }
        let tv = info.kp_proc.p_starttime
        let seconds = TimeInterval(tv.tv_sec)
        let micro = TimeInterval(tv.tv_usec) / 1_000_000.0
        return seconds + micro
        #else
        return nil
        #endif
    }

    static func memoryUsageMB() -> Double? {
        #if canImport(Darwin)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return nil }
        return Double(info.resident_size) / 1024.0 / 1024.0
        #else
        return nil
        #endif
    }

    static func cpuUsagePercent() -> Double? {
        #if canImport(Darwin)
        var threads: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let kr = task_threads(mach_task_self_, &threads, &threadCount)
        guard kr == KERN_SUCCESS, let threadList = threads else { return nil }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(threadList[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            if result == KERN_SUCCESS, (info.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), size)
        return totalUsage
        #else
        return nil
        #endif
    }
}
