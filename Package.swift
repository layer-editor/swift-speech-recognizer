// swift-tools-version:5.7
//
//  Package.swift
//  SwiftSpeechRecognizer
//
//  Created by Renaud Jenny on 2/18/21.
//

import PackageDescription

let package = Package(
    name: "swift-speech-recognizer",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "SwiftSpeechRecognizer", targets: ["SwiftSpeechRecognizer"]),
        .library(name: "SwiftSpeechCombine", targets: ["SwiftSpeechCombine"]),
    ],
    targets: [
        .target(name: "SwiftSpeechRecognizer", dependencies: []),
        .testTarget(name: "SwiftSpeechRecognizerTests", dependencies: ["SwiftSpeechRecognizer"]),
        .target(name: "SwiftSpeechCombine", dependencies: ["SwiftSpeechRecognizer"]),
    ]
)
