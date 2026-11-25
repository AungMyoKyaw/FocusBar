import Foundation
import AppKit

final class DistractionGuardService {
    var onDistractingAppActivated: ((String) -> Void)?

    private var observer: NSObjectProtocol?
    private var isMonitoring = false
    private var blockedBundleIDs: Set<String> = []
    private var lastNudgeDates: [String: Date] = [:]

    func startMonitoring(blockedBundleIDs: [String]) {
        self.blockedBundleIDs = Set(blockedBundleIDs.map { $0.lowercased() })
        guard !isMonitoring, !self.blockedBundleIDs.isEmpty else { return }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier?.lowercased() else { return }

            if self.blockedBundleIDs.contains(bundleID) {
                let now = Date()
                if let last = self.lastNudgeDates[bundleID], now.timeIntervalSince(last) < 60 {
                    return
                }
                self.lastNudgeDates[bundleID] = now
                let name = app.localizedName ?? bundleID
                self.onDistractingAppActivated?(name)
            }
        }
        isMonitoring = true
    }

    func stopMonitoring() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
        isMonitoring = false
    }

    deinit {
        stopMonitoring()
    }
}
