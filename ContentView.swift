import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SiriAIViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    modeSwitcher
                    conversationArea
                    voiceControl
                    composer
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 26)
            }
        }
        .tint(.white)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
        }
        .task(id: selectedPhotoItem?.itemIdentifier) {
            guard let selectedPhotoItem else { return }
            await viewModel.attachPhoto(from: selectedPhotoItem)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    AvatarOrb()
                        .frame(width: 34, height: 34)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Siri AI")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Gemini-powered liquid glass assistant")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                GlassDockButton(systemName: "gearshape.fill", tint: .white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .glassPanel(cornerRadius: 28)
    }

    private var modeSwitcher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modes")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 10) {
                ForEach(AssistantMode.allCases) { mode in
                    Button {
                        viewModel.selectedMode = mode
                    } label: {
                        ModePill(mode: mode, isSelected: viewModel.selectedMode == mode)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(viewModel.selectedMode.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(16)
        .glassPanel(cornerRadius: 28)
    }

    private var conversationArea: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Conversation")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.84))

                Spacer()

                if viewModel.isSending {
                    HStack(spacing: 8) {
                        ThinkingIndicator()
                        Text("Live Activity")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }

                if let error = viewModel.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 28)
    }

    private var composer: some View {
        VStack(spacing: 12) {
            if let name = viewModel.attachedImageName {
                HStack {
                    Label(name, systemImage: "photo.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer()
                    Button("Remove") {
                        viewModel.clearAttachment()
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassPanel(cornerRadius: 22)
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    GlassDockButton(systemName: "plus", tint: .white)
                }
                .buttonStyle(.plain)

                TextField("Ask Siri AI", text: $viewModel.draftText, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Button {
                    Task {
                        if viewModel.isVoiceTranscribing {
                            viewModel.stopVoiceTranscription()
                        } else {
                            await viewModel.startVoiceTranscription()
                        }
                    }
                } label: {
                    GlassDockButton(
                        systemName: viewModel.isVoiceTranscribing ? "stop.fill" : "mic.fill",
                        tint: viewModel.isVoiceTranscribing ? .red : .white
                    )
                }
                .buttonStyle(.plain)

                Button {
                    Task { await viewModel.send() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)

                        if viewModel.isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSending)
            }
            .padding(14)
            .background(Color.black.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(16)
        .glassPanel(cornerRadius: 30)
    }

    private var voiceControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Voice Dictation")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.84))
                Spacer()
                Text(viewModel.isVoiceTranscribing ? "Listening" : "Ready")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Text(viewModel.voiceTranscript.isEmpty ? "Tap the mic to dictate into the composer using Apple Speech." : viewModel.voiceTranscript)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.76))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let error = viewModel.voicePermissionError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.95))
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 28)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SiriAIViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    settingsField(
                        title: "Gemini API Key",
                        subtitle: "Required for real answers"
                    ) {
                        SecureField("Paste your key", text: Binding(
                            get: { viewModel.apiKey },
                            set: { viewModel.setAPIKey($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                    }

                    settingsField(
                        title: "Model",
                        subtitle: "Use a Gemini model name"
                    ) {
                        TextField("gemini-2.5-flash", text: Binding(
                            get: { viewModel.modelName },
                            set: { viewModel.setModelName($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                    }

                    Text("Live Activities are started from foreground sends and shown in the Lock Screen / Dynamic Island when supported by the device.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
            }
        }
    }

    @ViewBuilder
    private func settingsField<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.68))
            }

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(16)
        .glassPanel(cornerRadius: 26)
    }
}
