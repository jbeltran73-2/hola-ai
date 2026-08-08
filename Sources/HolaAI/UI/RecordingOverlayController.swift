import AppKit
import SwiftUI

/// Controller for the floating recording overlay window
@MainActor
final class RecordingOverlayController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<RecordingOverlayView>?

    private var isRecording = false
    private var isTranscribing = false
    private var audioLevel: Float = 0
    private var intent: DictationIntent = .transcription
    private var translateToEnglish: Bool = false
    private var canCopyLastText = false
    private var isExpanded = false

    /// Pill-shaped bar. Extra height is transparent (status / expanded chips).
    private let idleSize = NSSize(width: 340, height: 140)
    private let activeSize = NSSize(width: 340, height: 140)

    /// Callback when the toggle button is pressed
    var onToggle: ((DictationOptions) -> Void)?
    var onCopyLastText: (() -> Void)?
    var onClose: (() -> Void)?

    /// Show the overlay (always visible, ready to record)
    func show() {
        guard panel == nil else { return }

        // nonactivatingPanel: clicks do not steal focus from the text field
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: idleSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.hasShadow = false

        // Fully transparent chrome — only SwiftUI capsule should paint pixels
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titlebarAppearsTransparent = true

        let overlayView = makeView()
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.autoresizingMask = [.width, .height]
        // Critical: NSHostingView defaults can paint an opaque cream/gray backdrop
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false

        panel.contentView = hostingView
        if let contentView = panel.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
            contentView.layer?.isOpaque = false
        }

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true

        positionWindow(panel)
        panel.orderFront(nil)
        self.hostingView = hostingView
        self.panel = panel
    }

    /// Hide the overlay completely
    func hide() {
        panel?.contentView = nil
        hostingView = nil
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }

    /// Update the recording state
    func setRecording(_ recording: Bool) {
        isRecording = recording

        if !recording {
            intent = .transcription
            translateToEnglish = false
        }

        updateView()
        resizePanel(forRecording: recording)
    }

    /// Update the transcribing state (show spinner)
    func setTranscribing(_ transcribing: Bool) {
        isTranscribing = transcribing
        updateView()
        resizePanel(forRecording: isRecording || transcribing)
    }

    /// Update the audio level visualization
    func updateAudioLevel(_ level: Float) {
        // Skip tiny no-ops to reduce SwiftUI thrashing while still feeling live
        if abs(level - audioLevel) < 0.01, level > 0.02 { return }
        audioLevel = level
        updateView()
    }

    /// Update whether copy-last-text button should be enabled
    func setCopyAvailable(_ available: Bool) {
        canCopyLastText = available
        updateView()
    }

    private func makeView() -> RecordingOverlayView {
        RecordingOverlayView(
            isRecording: isRecording,
            isTranscribing: isTranscribing,
            audioLevel: audioLevel,
            intent: intent,
            translateToEnglish: translateToEnglish,
            canCopyLastText: canCopyLastText,
            isExpanded: isExpanded,
            onToggle: { [weak self] options in
                self?.onToggle?(options)
            },
            onIntentChange: { [weak self] newIntent in
                self?.intent = newIntent
                if newIntent == .prompt {
                    self?.translateToEnglish = true
                }
                self?.updateView()
            },
            onTranslateChange: { [weak self] shouldTranslate in
                self?.translateToEnglish = shouldTranslate
                self?.updateView()
            },
            onCopyLastText: { [weak self] in
                self?.onCopyLastText?()
            },
            onClose: { [weak self] in
                self?.onClose?()
            },
            onExpandChange: { [weak self] expanded in
                self?.isExpanded = expanded
                self?.updateView()
            }
        )
    }

    private func updateView() {
        hostingView?.rootView = makeView()
        // Re-assert clear background after SwiftUI updates
        hostingView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel?.backgroundColor = .clear
        panel?.isOpaque = false
    }

    private func resizePanel(forRecording active: Bool) {
        guard let panel = panel else { return }
        let newSize = active ? activeSize : idleSize
        var frame = panel.frame
        let widthDiff = newSize.width - frame.width
        let heightDiff = newSize.height - frame.height
        frame.size.width = newSize.width
        frame.size.height = newSize.height
        frame.origin.x -= widthDiff
        frame.origin.y -= heightDiff
        panel.setFrame(frame, display: true, animate: true)
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let screenRect = screen.visibleFrame
        let padding: CGFloat = 24
        let windowSize = window.frame.size

        let x = screenRect.maxX - windowSize.width - padding
        let y = screenRect.minY + padding

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
