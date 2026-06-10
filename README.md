# Siri AI

SwiftUI app scaffold for an iPhone/iPad assistant branded as Siri AI, with:

- liquid-glass-inspired UI
- Gemini-backed chat, image analysis, and voice-oriented modes
- Live Activities and Dynamic Island presentation for ongoing prompts

## Important build note

I can create the source for the app here, but I cannot produce a working `.ipa` from this Windows sandbox.
To export an `.ipa`, you need Xcode on macOS plus valid Apple signing assets.

Apple’s docs for Live Activities and app distribution:

- [Displaying live data with Live Activities](https://developer.apple.com/documentation/ActivityKit/displaying-live-data-with-live-activities)
- [ActivityKit](https://developer.apple.com/documentation/ActivityKit/)
- [Preparing your app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution/)
- [Distributing your app to registered devices](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)

## What is included

- `SiriAIApp.swift`: app entry point
- `ContentView.swift`: main glass UI
- `SiriAIViewModel.swift`: message flow and send logic
- `GeminiService.swift`: REST wrapper for Gemini with a demo fallback when no API key exists
- `SiriAILiveActivity.swift`: ActivityKit coordinator and activity attributes
- `SiriAIWidget.swift`: Live Activity / Dynamic Island UI

## What you still need in Xcode

- Add the files to an iOS app target and a widget extension target
- Enable `Live Activities` capability
- Add `NSSupportsLiveActivities` to the app’s Info.plist
- Add `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to the app’s Info.plist
- Add your Gemini API key in app settings or wire it to your own secure storage
- Build and archive on macOS, then export the `.ipa` from Xcode

## Voice transcription

The app now includes an Apple Speech dictation path that:

- requests speech recognition permission
- requests microphone permission
- streams partial transcriptions into the composer
- lets you stop dictation with the same mic control

Apple docs:

- [Speech framework](https://developer.apple.com/documentation/speech/)
- [SFSpeechRecognizer](https://developer.apple.com/documentation/speech/sfspeechrecognizer)
- [SFSpeechAudioBufferRecognitionRequest](https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest)

## Suggested minimum deployment target

- iOS 16.1 or later for Live Activities
- iOS 17 or later is a comfortable target for the latest SwiftUI polish
