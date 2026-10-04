// swift-tools-version: 5.10
import PackageDescription
let package = Package(
    name: "Voicex",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", exact: "1.1.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", exact: "2.4.0")
    ],
    targets: [
        .executableTarget(name: "Voicex", dependencies: [
            .product(name: "WhisperKit", package: "argmax-oss-swift"),
            .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
        ], path: "Sources"),
        .testTarget(name: "VoicexTests", dependencies: ["Voicex"], path: "Tests")
    ]
)
