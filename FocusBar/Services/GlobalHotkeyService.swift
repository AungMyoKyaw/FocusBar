import Foundation
import Carbon.HIToolbox

final class GlobalHotkeyService {
    var onStartPause: (() -> Void)?
    var onReset: (() -> Void)?
    var onSkip: (() -> Void)?

    private var eventHandlerRef: EventHandlerRef?
    private var startPauseRef: EventHotKeyRef?
    private var resetRef: EventHotKeyRef?
    private var skipRef: EventHotKeyRef?
    private var isRegistered = false

    private static let signature: OSType = 0x46424152 // 'FBAR'

    func setEnabled(_ enabled: Bool) {
        if enabled {
            register()
        } else {
            unregister()
        }
    }

    func register() {
        guard !isRegistered else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData -> OSStatus in
                guard let userData, let eventRef else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard err == noErr else { return err }
                DispatchQueue.main.async {
                    service.handleHotKey(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard status == noErr else {
            LoggingService.logError(.unknown("Failed to install global hotkey handler: \(status)"), context: "GlobalHotkeyService")
            return
        }

        let modifiers = UInt32(cmdKey | optionKey | controlKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_S), modifiers, EventHotKeyID(signature: Self.signature, id: 1), GetApplicationEventTarget(), 0, &startPauseRef)
        RegisterEventHotKey(UInt32(kVK_ANSI_R), modifiers, EventHotKeyID(signature: Self.signature, id: 2), GetApplicationEventTarget(), 0, &resetRef)
        RegisterEventHotKey(UInt32(kVK_ANSI_N), modifiers, EventHotKeyID(signature: Self.signature, id: 3), GetApplicationEventTarget(), 0, &skipRef)

        isRegistered = true
        LoggingService.logInfo("Global hotkeys registered (Ctrl+Opt+Cmd+S/R/N)", category: .timer)
    }

    func unregister() {
        if let startPauseRef { UnregisterEventHotKey(startPauseRef) }
        if let resetRef { UnregisterEventHotKey(resetRef) }
        if let skipRef { UnregisterEventHotKey(skipRef) }
        startPauseRef = nil
        resetRef = nil
        skipRef = nil

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
        eventHandlerRef = nil
        isRegistered = false
    }

    private func handleHotKey(id: UInt32) {
        switch id {
        case 1: onStartPause?()
        case 2: onReset?()
        case 3: onSkip?()
        default: break
        }
    }

    deinit {
        unregister()
    }
}
