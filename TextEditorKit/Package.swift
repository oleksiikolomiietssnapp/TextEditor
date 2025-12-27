// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TextEditorKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "TextEditorKit", targets: ["TextEditorKit"])
    ],
    targets: [
        .target(name: "TextEditorKit")
    ]
)
