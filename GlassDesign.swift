import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                    Color(red: 0.03, green: 0.05, blue: 0.12),
                    Color(red: 0.01, green: 0.01, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.32),
                            Color.blue.opacity(0.16),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 280
                    )
                )
                .blur(radius: 40)
                .offset(x: -130, y: -240)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.pink.opacity(0.26),
                            Color.orange.opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
                .blur(radius: 48)
                .offset(x: 160, y: 320)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 18)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 28) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius))
    }
}

struct ModePill: View {
    let mode: AssistantMode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.iconName)
            Text(mode.title)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(isSelected ? .black : .white.opacity(0.92))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [Color.white, Color.white.opacity(0.84)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.12))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.08 : 0.16), lineWidth: 1)
        )
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .assistant {
                AvatarOrb()
            } else {
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.role == .assistant ? .white : .black)
                    .frame(maxWidth: 280, alignment: .leading)

                if message.imageData != nil {
                    Image(systemName: "photo")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(message.role == .assistant ? .white.opacity(0.82) : .black.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(message.role == .assistant ? Color.white.opacity(0.12) : Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(message.role == .assistant ? 0.12 : 0.35), lineWidth: 1)
            )

            if message.role == .user {
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

struct AvatarOrb: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan,
                            Color.blue,
                            Color.purple,
                            Color.pink
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .scaleEffect(pulse ? 1.06 : 0.96)
                .shadow(color: Color.cyan.opacity(0.34), radius: 10, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct ThinkingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 7, height: 7)
                    .offset(y: CGFloat(sin(phase + Double(index) * 0.8)) * 5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct GlassDockButton: View {
    let systemName: String
    let tint: Color
    var body: some View {
        Image(systemName: systemName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 42, height: 42)
            .background(Color.white.opacity(0.08))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

