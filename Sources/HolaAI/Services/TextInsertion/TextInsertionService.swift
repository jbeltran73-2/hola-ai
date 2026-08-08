import AppKit
import ApplicationServices
import os.log

/// Errors that can occur during text insertion
enum TextInsertionError: Error, LocalizedError {
    case accessibilityNotGranted
    case noFocusedElement
    case insertionFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Accessibility access is required. Please enable HolaAI in System Settings → Privacy & Security → Accessibility."
        case .noFocusedElement:
            return "No text field is currently focused. Click on a text field and try again."
        case .insertionFailed:
            return "Failed to insert text. The application may not support text insertion."
        }
    }
}

/// Service responsible for inserting text into the currently focused text field
@MainActor
final class TextInsertionService {
    private let logger = Logger(subsystem: "com.holaai.app", category: "TextInsertion")

    /// App that was frontmost when dictation started (restored before paste)
    private var targetApplication: NSRunningApplication?

    /// Check if Accessibility permission is granted
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request Accessibility permission (opens System Settings)
    func requestAccessibilityPermission() {
        let options: NSDictionary = ["AXTrustedCheckOptionPrompt": true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Remember the frontmost app so we can return focus after transcription
    func captureTargetApplication() {
        // Prefer the frontmost non-ourselves app
        let selfPID = ProcessInfo.processInfo.processIdentifier
        if let front = NSWorkspace.shared.frontmostApplication,
           front.processIdentifier != selfPID {
            targetApplication = front
            print("🎯 [TextInsertion] Target app: \(front.localizedName ?? "?") (pid \(front.processIdentifier))")
            return
        }

        // Fallback: first regular active app that isn't us
        targetApplication = NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular
                && !$0.isTerminated
                && $0.processIdentifier != selfPID
                && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        }
        if let app = targetApplication {
            print("🎯 [TextInsertion] Fallback target: \(app.localizedName ?? "?")")
        } else {
            print("⚠️ [TextInsertion] No target app captured")
        }
    }

    /// Insert text at the current cursor position
    func insertText(_ text: String) throws {
        print("🔐 [TextInsertion] Checking Accessibility permission...")
        let hasPermission = AXIsProcessTrusted()
        print("🔐 [TextInsertion] Accessibility: \(hasPermission ? "✅ GRANTED" : "❌ NOT GRANTED")")

        if !hasPermission {
            print("💡 [TextInsertion] Enable: System Settings → Privacy & Security → Accessibility → HolaAI")
            requestAccessibilityPermission()
            throw TextInsertionError.accessibilityNotGranted
        }

        // Bring the original app back so paste lands in the right place
        restoreTargetApplication()

        // Brief pause so the target app becomes key and cursor is active
        Thread.sleep(forTimeInterval: 0.12)

        try insertTextViaPasteboard(text)
    }

    /// Activate the app that was frontmost when recording started
    private func restoreTargetApplication() {
        guard let app = targetApplication, !app.isTerminated else {
            print("⚠️ [TextInsertion] No target app to restore — pasting into current focus")
            return
        }
        let activated: Bool
        if #available(macOS 14.0, *) {
            activated = app.activate()
        } else {
            activated = app.activate(options: [.activateIgnoringOtherApps])
        }
        print("🎯 [TextInsertion] Activated \(app.localizedName ?? "?") → \(activated)")
    }

    /// Insert text by copying to pasteboard and simulating Cmd+V
    private func insertTextViaPasteboard(_ text: String) throws {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        pasteboard.clearContents()
        let ok = pasteboard.setString(text, forType: .string)
        guard ok else {
            throw TextInsertionError.insertionFailed
        }
        print("📋 [TextInsertion] Text on clipboard (\(text.count) chars)")

        // Let the pasteboard settle (some apps read async)
        Thread.sleep(forTimeInterval: 0.05)

        print("⌨️ [TextInsertion] Simulating Cmd+V...")
        simulatePaste()

        // Restore previous clipboard after paste has had time to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Only restore if nothing else changed the pasteboard in the meantime
            if pasteboard.changeCount == previousChangeCount + 1 || pasteboard.string(forType: .string) == text {
                if let previous = previousContent {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                    print("📋 [TextInsertion] Previous clipboard restored")
                }
            }
        }

        logger.info("Text inserted via pasteboard: \(text.prefix(30))...")
    }

    /// Simulate Cmd+V keystroke (down + up) via HID event tap
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        source?.localEventsSuppressionInterval = 0

        let keyVCode: CGKeyCode = 9 // 'V'

        // Some apps need the modifier pressed first
        if let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 55, keyDown: true) { // left command
            cmdDown.flags = .maskCommand
            cmdDown.post(tap: .cghidEventTap)
        }

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyVCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }

        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyVCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }

        if let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 55, keyDown: false) {
            cmdUp.flags = []
            cmdUp.post(tap: .cghidEventTap)
        }
    }

    /// Insert text character by character using CGEvents (fallback, no pasteboard)
    func insertTextViaKeyEvents(_ text: String) {
        restoreTargetApplication()
        Thread.sleep(forTimeInterval: 0.1)

        let source = CGEventSource(stateID: .hidSystemState)

        for character in text {
            guard character.unicodeScalars.first != nil else { continue }

            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(string: String(character))
                keyDown.post(tap: .cghidEventTap)
            }

            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(string: String(character))
                keyUp.post(tap: .cghidEventTap)
            }

            Thread.sleep(forTimeInterval: 0.001)
        }

        logger.info("Text inserted via key events: \(text.prefix(30))...")
    }
}

// MARK: - CGEvent Extension for Unicode String

extension CGEvent {
    func keyboardSetUnicodeString(string: String) {
        let utf16 = Array(string.utf16)
        let length = utf16.count
        utf16.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                self.keyboardSetUnicodeString(stringLength: length, unicodeString: baseAddress)
            }
        }
    }
}
