import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceTranscriptionManager: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var micPermissionGranted: Bool = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        micPermissionGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startListening(onPartialText: @escaping @MainActor (String) -> Void) async {
        errorMessage = nil
        transcript = ""

        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition permission is required."
            await refreshAuthorization()
            return
        }

        guard micPermissionGranted else {
            errorMessage = "Microphone permission is required."
            await refreshAuthorization()
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is unavailable right now."
            return
        }

        if audioEngine.isRunning {
            stopListening()
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not configure audio session."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isListening = true
        } catch {
            errorMessage = "Could not start the microphone."
            stopListening()
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    onPartialText(self.transcript)
                }

                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        guard isListening || recognitionTask != nil else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
