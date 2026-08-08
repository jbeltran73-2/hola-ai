import AppKit
import SwiftUI

/// NSHostingView that never paints an opaque window-sized backdrop
private final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        clearChrome()
    }

    override func layout() {
        super.layout()
        clearChrome()
    }

    private func clearChrome() {
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
        // Avoid AppKit filling behind SwiftUI
        if let layer {
            layer.backgroundColor = .clear
        }
    }
}

/// Controller for the floating recording overlay window
@MainActor
final class RecordingOverlayController {
    private var panel: NSPanel?
    private var hostingView: ClearHostingView<RecordingOverlayView>?

    private var isRecording = false
    private var isTranscribing = false
    private var audioLevel: Float = 0
    private var intent: DictationIntent = .transcription
    private var translateToEnglish: Bool = false
    private var canCopyLastText = false
    private var isExpanded = false

    /// Tight size: only the pill (+ room for chips / status). Extra is transparent.
    private let idleSize = NSSize(width: 300, height: 64)
    private let recordingSize = NSSize(width: 300, height: 96)
    private let expandedSize = NSSize(width: 320, height: 120)

    var onToggle: ((DictationOptions) -> Void)?
    var onCopyLastText: (() -> Void)?
    var onClose: (() -> Void)?

    func show() {
        guard panel == nil else { return }

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
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titlebarAppearsTransparent = true
        // Prevent the system from drawing a window backdrop
        panel.styleMask.insert(.fullSizeContentView)

        let hostingView = ClearHostingView(rootView: makeView())
        hostingView.frame = NSRect(origin: .zero, size: idleSize)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.isOpaque = false

        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true

        positionWindow(panel)
        panel.orderFront(nil)
        self.hostingView = hostingView
        self.panel = panel
    }

    func hide() {
        panel?.contentView = nil
        hostingView = nil
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }

    func setRecording(_ recording: Bool) {
        isRecording = recording
        if !recording {
            intent = .transcription
            translateToEnglish = false
        }
        updateView()
        resizePanel()
    }

    func setTranscribing(_ transcribing: Bool) {
        isTranscribing = transcribing
        updateView()
        resizePanel()
    }

    func updateAudioLevel(_ level: Float) {
        if abs(level - audioLevel) < 0.01, level > 0.02 { return }
        audioLevel = level
        updateView()
    }

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
                self?.resizePanel()
            }
        )
    }

    private func updateView() {
        hostingView?.rootView = makeView()
        hostingView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel?.backgroundColor = .clear
        panel?.isOpaque = false
        panel?.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func currentSize() -> NSSize {
        if isExpanded { return expandedSize }
        if isRecording || isTranscribing { return recordingSize }
        return idleSize
    }

    private func resizePanel() {
        guard let panel = panel else { return }
        let newSize = currentSize()
        var frame = panel.frame
        let widthDiff = newSize.width - frame.width
        let heightDiff = newSize.height - frame.height
        frame.size = newSize
        // Keep right edge; grow upward
        frame.origin.x -= widthDiff
        frame.origin.y -= heightDiff
        panel.setFrame(frame, display: true, animate: true)
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let padding: CGFloat = 24
        let size = window.frame.size
        let x = screenRect.maxX - size.width - padding
        let y = screenRect.minY + padding
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
