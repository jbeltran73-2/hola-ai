import SwiftUI

struct ContentView: View {
    private let softInk = Color(red: 0.28, green: 0.24, blue: 0.22)
    private let bronze = Color(red: 0.62, green: 0.48, blue: 0.36)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.95, blue: 0.91),
                    Color(red: 0.97, green: 0.88, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // Infinity / voice mark
                Text("∞")
                    .font(.system(size: 44, weight: .ultraLight, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .shadow(color: bronze.opacity(0.25), radius: 8, y: 2)

                Rectangle()
                    .fill(bronze.opacity(0.35))
                    .frame(width: 28, height: 1)

                VStack(spacing: 6) {
                    Text("HOLA-AI")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(softInk.opacity(0.85))

                    Text("VOICE DICTATION")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(softInk.opacity(0.55))
                }

                Text("Speak into any app. Press the mic or hold Fn.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(softInk.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(40)
        }
        .frame(minWidth: 320, minHeight: 240)
    }
}

#Preview {
    ContentView()
}
