// swift-tools-version: 5.9
//
//  Package.swift
//  BetterCMTrace
//
//  A Swift package describing the BetterCMTrace application.  The
//  package is configured to build a macOS application using SwiftUI.
//  You can open this package directly in Xcode (File ▸ Open) to
//  generate an Xcode project.  Running the resulting app will
//  launch the log viewer implemented in the Sources directory.

import PackageDescription

let package = Package(
    name: "BetterCMTrace",
    platforms: [
        // Target macOS 13 or later to leverage the latest SwiftUI and
        // concurrency features.  You can lower this version if
        // required, but some APIs might need adjustment.
        .macOS(.v13)
    ],
    products: [
        // Define a macOS application.  Xcode will automatically
        // generate an executable bundle from the App declaration in
        // Sources/BetterCMTrace/BetterCMTraceApp.swift.
        .executable(
            name: "BetterCMTrace",
            targets: ["BetterCMTrace"]
        )
    ],
    dependencies: [
        // No external dependencies.  All functionality is self-contained.
    ],
    targets: [
        .target(
            name: "BetterCMTrace",
            dependencies: [],
            path: "Sources"
        )
    ]
)
