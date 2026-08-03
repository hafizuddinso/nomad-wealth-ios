import SwiftUI
import UIKit

enum AppHaptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct ScalePressButtonStyle: ButtonStyle {
    var tint: Color
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .foregroundStyle(foreground)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct AnimatedCard<Content: View>: View {
    let delay: Double
    @ViewBuilder let content: Content
    @State private var appeared = false

    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86).delay(delay)) {
                    appeared = true
                }
            }
    }
}

struct LoadingButtonLabel: View {
    let title: String
    let loading: Bool

    var body: some View {
        HStack(spacing: 10) {
            if loading {
                ProgressView()
                    .tint(.white)
            }
            Text(loading ? "Please wait…" : title)
        }
        .frame(maxWidth: .infinity)
    }
}
