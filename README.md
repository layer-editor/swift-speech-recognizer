# SwiftSpeechRecognizer

[![Swift Test](https://github.com/renaudjenny/swift-speech-recognizer/actions/workflows/test.yml/badge.svg)](https://github.com/renaudjenny/swift-speech-recognizer/actions/workflows/test.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frenaudjenny%2Fswift-speech-recognizer%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/renaudjenny/swift-speech-recognizer)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Frenaudjenny%2Fswift-speech-recognizer%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/renaudjenny/swift-speech-recognizer)

This package contains some very straightforward wrappers around around Speech Recognition part of SFSpeechRecognizer to allow you using this with ease.

* `SwiftSpeechRecognizer` Using **Swift Concurrency** with `async` `await`, a couple of `AsyncStream`
* `SwiftSpeechCombine` the OG library still available in this package

This maintained `layer-editor` fork provides the async and Combine products without external package dependencies. The unused `SwiftSpeechRecognizerDependency` product has been removed. This is a breaking change for clients importing that adapter; those clients should stay on the existing `1.0.0` tag or the upstream package until they migrate. The native recognizer and Combine implementations are unchanged.

## Authorization

⚠️ For Speech Recognition to be allowed to work, you must add `NSSpeechRecognitionUsageDescription` in your app Info.plist with a description of its usage. 

## Modern concurrency usage

```swift
import Speech
import SwiftSpeechRecognizer

struct SpeechRecognizer {

    var authorizationStatusChanged: (SFSpeechRecognizerAuthorizationStatus) -> Void
    var speechRecognitionStatusChanged: (SpeechRecognitionStatus) -> Void
    var utteranceChanged: (String) -> Void

    private let speechRecognizer = SwiftSpeechRecognizer.live

    func start() {
        speechRecognizer.requestAuthorization()
        Task {
            for await authorizationStatus in speechRecognizer.authorizationStatus() {
                authorizationStatusChanged(authorizationStatus)

                switch authorizationStatus {
                case .authorized:
                    startRecording()
                default:
                    print("Not authorized to use speech recognizer")
                }
            }
        }
    }

    private func startRecording() {
        do {
            try speechRecognizer.startRecording()
            Task {
                for await recognitionStatus in speechRecognizer.recognitionStatus() {
                    speechRecognitionStatusChanged(recognitionStatus)
                }
            }

            Task {
                for await newUtterance in speechRecognizer.newUtterance() {
                    utteranceChanged(newUtterance)
                }
            }
        } catch {
            print("Something went wrong: \(error)")
            speechRecognizer.stopRecording()
        }
    }
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        Button {
            let speechRecognizer = SpeechRecognizer(
                authorizationStatusChanged: { newAuthorizationStatus in
                    print("Authorization status changed: \(newAuthorizationStatus)")
                },
                speechRecognitionStatusChanged: { newRecognitionStatus in
                    print("Recognition status changed: \(newRecognitionStatus)")
                },
                utteranceChanged: { newUtterance in
                    print("Recognized utterance changed: \(newUtterance)")
                }
            )
            speechRecognizer.start()
        } label: {
            Text("Start speech recognizer")
        }
    }
}
```

## Combine usage

You can instantiate/inject `SpeechRecognitionEngine` object, it has this behavior

* `func requestAuthorization()`: call this method when you want to ask user if you can use Speech Recognition. Please, follow Apple Human Guidelines recommendations: [Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/speech/asking_permission_to_use_speech_recognition)
  * subscribe to `authorizationStatusPublisher` to know when and what's the user decision (see below)
* `func startRecording() throws`: call this method when you want to start the speech recognition, all the complexity with `AVAudioEngine` is hidden behind this function.
  * subscribe to `recognizedUtterancePublisher` or `newUtterancePublisher` depending on your needs. See below the difference
* `func stopRecording()`: call this method when you want the speech recognition to stop

* `var authorizationStatusPublisher`: subscribe to this to know what's the current authorization status of the speech recognition (this authorization include the microphone usage)
* `var recognizedUtterancePublisher`: subscribe to this to know when a `String` is recognized
* `var isRecognitionAvailablePublisher`: subscribe to this to know when the recognition status changed. It could be:
  * `notStarted`: no recognition has started yet for the session
  * `recording`: the recognition is processing
  * `stopping`: a stop recognition has just been triggered
  * `stopped`: the recognition is stopped, and is ready to start the next recognition
* `var isRecognitionAvailablePublisher`: subscribe to this to know when the Speech Recognition is available on the device (like if the internet connection allows the Speech Recognition to be processed)
* `var newUtterancePublisher`: subscribe to this if you're only interested in "new" actual utterance. It's actually a shortcut of `recognizedUtterancePublisher` while it removes duplicates and only take an actual String (so it's never `nil`)

### Example

```swift
import Combine
import Speech
import SwiftSpeechCombine

let engine: SpeechRecognitionEngine = SpeechRecognitionSpeechEngine()
var cancellables = Set<AnyCancellable>()

// Only start to record if you're authorized to do so!
func speechRecognitionStatusChanged(authorizationStatus: SFSpeechRecognizerAuthorizationStatus) {
    guard authorizationStatus == .authorized
    else { return }

    do {
        try engine.startRecording()

        engine.newUtterancePublisher
            .sink { newUtterance in
                // Do whatever you want with the recognized utterance...
                print(newUtterance)
            }
            .store(in: &cancellables)

        engine.recognitionStatusPublisher
            .sink { status in
                // Very useful to notify the user of the current status
                setTheButtonState(status: status)
            }
            .store(in: &cancellables)
    } catch {
        print(error)
        engine.stopRecording()
    }
}

func setTheButtonState(status: SpeechRecognitionStatus) {
    switch status {
    case .notStarted: print("The button is ready to be tapped")
    case .recording: print("The button is showing a progress spinner")
    case .stopping: print("The button is disabled")
    case .stopped: print("The button is ready to be tapped for a new recognition")
    }
}

engine.requestAuthorization()

engine.authorizationStatusPublisher
    .compactMap { $0 }
    .sink { authorizationStatus in
        speechRecognitionStatusChanged(authorizationStatus: authorizationStatus)
    }
    .store(in: &cancellables)
```

## Installation

### Xcode

You can add SwiftSpeechCombine to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency...**
2. Enter "https://github.com/layer-editor/swift-speech-recognizer" into the package repository URL test field
3. Select the `main` branch, then choose either library that you are interested in. See [above](#swiftspeechrecognizer)

### As package dependency

Edit your `Package.swift` to add this library.

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/layer-editor/swift-speech-recognizer", branch: "main"),
        ...
    ],
    targets: [
        .target(
            name: "<Your project name>",
            dependencies: [
                .product(name: "SwiftSpeechRecognizer", package: "swift-speech-recognizer"), // <-- Modern concurrency
                .product(name: "SwiftSpeechCombine", package: "swift-speech-recognizer"), // <-- Combine wrapper
            ]),
        ...
    ]
)
```

## App using this library

* [📲 Tell Time UK](https://apps.apple.com/gb/app/tell-time-uk/id1496541173): https://github.com/renaudjenny/telltime
