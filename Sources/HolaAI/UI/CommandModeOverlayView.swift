import SwiftUI

/// Floating overlay shown when command mode is active — matches frosted glass design language
struct CommandModeOverlayView: View {
    @State private var isPulsing = false
    let audioLevel: Float

    private let softInk = Color(red: 0.28, green: 0.24, blue: 0.22)
    private let bronze = Color(red: 0.62, green: 0.48, blue: 0.36)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "command")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(softInk.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            Circle()
                                .stroke(softInk.opacity(0.12), lineWidth: 1)
                        )
                )
                .scaleEffect(isPulsing ? 1.06 : 1.0)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Command Mode")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(softInk.opacity(0.9))

                Text("Say a command or “exit”")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(softInk.opacity(0.5))
            }

            WaveformMini(level: audioLevel, color: bronze)
                .frame(width: 56, height: 18)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.78))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

private struct WaveformMini: View {
    let level: Float
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let midY = size.height / 2
                let amp = CGFloat(0.2 + Double(level) * 0.7) * size.height * 0.4
                var path = Path()
                let steps = Int(size.width)
                for i in 0...steps {
                    let x = CGFloat(i)
                    let p = CGFloat(i) / size.width * .pi * 4
                    let env = sin(CGFloat(i) / size.width * .pi)
                    let y = midY + sin(p + CGFloat(t) * 3) * amp * env
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(
                    path,
                    with: .color(color.opacity(0.85)),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.93, blue: 0.88),
                Color(red: 0.96, green: 0.86, blue: 0.80)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        CommandModeOverlayView(audioLevel: 0.4)
    }
    .frame(width: 360, height: 120)
}
