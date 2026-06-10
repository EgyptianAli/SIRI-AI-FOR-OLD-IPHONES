import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct SiriAIWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SiriAIActivityAttributes.self) { context in
            SiriAILockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.92))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SiriAIIslandLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    SiriAIIslandTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    SiriAIIslandBottomView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.phase.symbolName)
                    .font(.caption.weight(.semibold))
            } compactTrailing: {
                Text(String(context.state.modeTitle.prefix(1)))
                    .font(.caption.weight(.bold))
                    .minimumScaleFactor(0.6)
            } minimal: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 16, height: 16)
            }
            .keylineTint(.white.opacity(0.24))
        }
    }
}

@available(iOS 16.1, *)
@main
struct SiriAIWidgetBundle: WidgetBundle {
    var body: some Widget {
        SiriAIWidget()
    }
}

@available(iOS 16.1, *)
struct SiriAILockScreenView: View {
    let context: ActivityViewContext<SiriAIActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 18, height: 18)

                    Text("Siri AI")
                        .font(.headline.weight(.semibold))
                }

                Spacer()

                Text(context.state.phase.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(context.state.prompt)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.white)

                Text(context.state.answerPreview)
                    .font(.footnote)
                    .lineLimit(3)
                    .foregroundStyle(.white.opacity(0.74))
            }

            ProgressView(value: context.state.progress)
                .tint(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 16.1, *)
struct SiriAIIslandLeadingView: View {
    let context: ActivityViewContext<SiriAIActivityAttributes>

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.state.phase.symbolName)
                .font(.caption.weight(.semibold))
            Text(context.state.phase.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
    }
}

@available(iOS 16.1, *)
struct SiriAIIslandTrailingView: View {
    let context: ActivityViewContext<SiriAIActivityAttributes>

    var body: some View {
        HStack(spacing: 6) {
            Text(context.state.modeTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Circle()
                .fill(Color.white.opacity(0.72))
                .frame(width: 6, height: 6)
        }
        .foregroundStyle(.white)
    }
}

@available(iOS 16.1, *)
struct SiriAIIslandBottomView: View {
    let context: ActivityViewContext<SiriAIActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(context.state.prompt)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                Spacer()
                if context.state.hasImage {
                    Image(systemName: "photo.fill")
                }
            }
            .foregroundStyle(.white)

            HStack {
                ProgressView(value: context.state.progress)
                    .tint(.white)

                Spacer()

                if context.state.isVoiceMode {
                    Label("Voice", systemImage: "mic.fill")
                        .font(.caption.weight(.semibold))
                } else {
                    Label(context.state.phase.title, systemImage: context.state.phase.symbolName)
                        .font(.caption.weight(.semibold))
                }
            }
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}
