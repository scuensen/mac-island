import Foundation
import IOKit.ps

@MainActor
final class SystemWidgetModel: ObservableObject {
    @Published var cpuPercent: Double = 0
    @Published var ramUsedGB: Double  = 0
    @Published var ramTotalGB: Double = 0
    @Published var batteryPercent: Int = -1  // -1 = no battery (desktop)
    @Published var isCharging = false

    private var timer: Foundation.Timer?

    func startPolling() {
        refresh()
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopPolling() { timer?.invalidate(); timer = nil }

    func refresh() {
        Task.detached(priority: .background) {
            let cpu = await Self.fetchCPU()
            let ram = Self.fetchRAM()
            let bat = Self.fetchBattery()
            await MainActor.run {
                self.cpuPercent    = cpu
                self.ramUsedGB     = ram.used
                self.ramTotalGB    = ram.total
                self.batteryPercent = bat.percent
                self.isCharging    = bat.charging
            }
        }
    }

    // MARK: CPU via top
    private static func fetchCPU() async -> Double {
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments  = ["-l", "2", "-n", "0", "-s", "1"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data   = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            // Last "CPU usage:" line
            let lines = output.components(separatedBy: "\n").filter { $0.contains("CPU usage:") }
            if let line = lines.last,
               let idleRange = line.range(of: #"(\d+\.?\d*)% idle"#, options: .regularExpression),
               let idleVal = Double(line[idleRange].components(separatedBy: "%").first ?? "") {
                return max(0, 100 - idleVal)
            }
        } catch {}
        return 0
    }

    // MARK: RAM via vm_stat
    private static func fetchRAM() -> (used: Double, total: Double) {
        let total = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize  = Double(vm_kernel_page_size)
        let usedPages = Double(stats.active_count + stats.wire_count + stats.compressor_page_count)
        let usedGB    = (usedPages * pageSize) / 1_073_741_824
        return (min(usedGB, total), total)
    }

    // MARK: Battery via IOKit
    private static func fetchBattery() -> (percent: Int, charging: Bool) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        for src in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, src).takeUnretainedValue() as? [String: Any] {
                let pct      = desc[kIOPSCurrentCapacityKey] as? Int ?? -1
                let charging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
                return (pct, charging)
            }
        }
        return (-1, false)
    }
}
