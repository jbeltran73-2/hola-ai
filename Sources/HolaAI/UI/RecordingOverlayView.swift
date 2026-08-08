import SwiftUI

/// Floating frosted-glass voice control bar (inspired by Voice Talk mockups)
struct RecordingOverlayView: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let audioLevel: Float
    let intent: DictationIntent
    let translateToEnglish: Bool
    let canCopyLastText: Bool
    let isExpanded: Bool
    var onToggle: ((DictationOptions) -> Void)?
    var onIntentChange: ((DictationIntent) -> Void)?
    var onTranslateChange: ((Bool) -> Void)?
    var onCopyLastText: (() -> Void)?
    var onClose: (() -> Void)?
    var onExpandChange: ((Bool) -> Void)?

    private let bronze = Color(red: 0.62, green: 0.48, blue: 0.36)
    private let softInk = Color(red: 0.22, green: 0.20, blue: 0.18)

    var body: some View {
        // IMPORTANT: size to content only — never fill the window with maxWidth/maxHeight,
        // or SwiftUI/material can paint a semi-opaque rectangle around the pill.
        VStack(alignment: .center, spacing: 8) {
            if isExpanded {
                expandedOptions
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            pillBar

            if isRecording || isTranscribing {
                statusLabel
                    .transition(.opacity)
            }
        }
        .padding(2)
        // Explicit clear — no material on the root
        .background(Color.clear)
    }

    // MARK: - Main bar

    private var pillBar: some View {
        HStack(spacing: 12) {
            circleButton(systemName: "plus") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    onExpandChange?(!isExpanded)
                }
            }
            .help("More options")
            .rotationEffect(.degrees(isExpanded ? 45 : 0))
            .animation(.easeInOut(duration: 0.2), value: isExpanded)

            WaveformCanvas(
                level: isRecording ? audioLevel : (isTranscribing ? 0.25 : 0.08),
                isActive: isRecording || isTranscribing,
                color: bronze
            )
            .frame(width: 148, height: 28)
            .opacity(isRecording || isTranscribing ? 1 : 0.7)

            micButton

            Button(action: { onClose?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.black.opacity(0.88)))
            }
            .buttonStyle(.plain)
            .help("Hide overlay")
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        // Glass fill clipped strictly to the capsule — no outer rect
        .background(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
    }

    // MARK: - Pieces

    private var micButton: some View {
        Button(action: {
            if !isTranscribing {
                onToggle?(DictationOptions(intent: intent, translateToEnglish: translateToEnglish))
            }
        }) {
            ZStack {
                Circle()
                    .fill(micBackground)
                    .frame(width: 36, height: 36)

                if isTranscribing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(softInk)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isRecording ? .white : softInk.opacity(0.9))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isTranscribing)
        .help(isRecording ? "Stop recording" : "Start dictation")
    }

    private var micBackground: Color {
        if isTranscribing {
            return Color(white: 0.96)
        }
        if isRecording {
            return Color(red: 0.86, green: 0.22, blue: 0.22)
        }
        return Color(white: 0.97)
    }

    private var expandedOptions: some View {
        HStack(spacing: 8) {
            optionChip(
                systemName: "sparkles",
                title: "Prompt",
                isOn: intent == .prompt,
                onColor: Color.orange
            ) {
                onIntentChange?(intent == .prompt ? .transcription : .prompt)
            }
            .disabled(isRecording || isTranscribing)

            optionChip(
                systemName: "globe",
                title: "EN",
                isOn: translateToEnglish || intent == .prompt,
                onColor: Color.blue
            ) {
                onTranslateChange?(!translateToEnglish)
            }
            .disabled(isRecording || isTranscribing || intent == .prompt)
            .opacity(intent == .prompt ? 0.55 : 1)

            optionChip(
                systemName: "doc.on.doc",
                title: "Copy",
                isOn: canCopyLastText,
                onColor: Color.green
            ) {
                onCopyLastText?()
            }
            .disabled(!canCopyLastText)
            .opacity(canCopyLastText ? 1 : 0.45)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        }
    }

    private var statusLabel: some View {
        HStack(spacing: 6) {
            if isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
            }

            Text(isTranscribing ? "Transcribing…" : "Listening…")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(softInk.opacity(0.85))
                .tracking(0.3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
        }
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(softInk.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func optionChip(
        systemName: String,
        title: String,
        isOn: Bool,
        onColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isOn ? .white : softInk.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isOn ? onColor : Color.white.opacity(0.7))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(isOn ? 0 : 0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

// MARK: - Waveform (voice-reactive)

private struct WaveformCanvas: View {
    let level: Float
    let isActive: Bool
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            WaveformShape(level: level, isActive: isActive, time: t, color: color)
        }
    }
}

private struct WaveformShape: View {
    let level: Float
    let isActive: Bool
    let time: TimeInterval
    let color: Color

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let boosted = min(1.0, Double(level) * 2.4)
            let amp = isActive ? (0.08 + boosted * 0.92) : 0.12
            let maxAmp = size.height * 0.48 * CGFloat(amp)
            let steps = max(Int(size.width), 2)

            var path = Path()
            for i in 0...steps {
                let progress = CGFloat(i) / CGFloat(steps)
                let x = progress * size.width
                let envelope = sin(progress * .pi)
                let p = progress * .pi * 2
                let t = CGFloat(time)
                let wave =
                    sin(p * 2.0 + t * 6.0) * 0.55
                    + sin(p * 3.5 + t * 4.2) * 0.30
                    + sin(p * 5.5 + t * 9.0) * 0.15
                let y = midY + wave * maxAmp * envelope
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(
                path,
                with: .color(color.opacity(isActive ? 0.95 : 0.45)),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Shared audio bars

struct AudioLevelView: View {
    let level: Float
    private let barCount = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)
                let isOn = level > threshold
                let barHeight = CGFloat(index + 1) * 4

                RoundedRectangle(cornerRadius: 2)
                    .fill(isOn ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 5, height: barHeight)
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 20, alignment: .bottom)
    }
}

#Preview("Idle") {
    ZStack {
        // Checkerboard so transparency is obvious
        Color.blue.opacity(0.35).ignoresSafeArea()
        RecordingOverlayView(
            isRecording: false,
            isTranscribing: false,
            audioLevel: 0,
            intent: .transcription,
            translateToEnglish: false,
            canCopyLastText: true,
            isExpanded: false
        )
    }
    .frame(width: 420, height: 180)
}
