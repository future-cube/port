// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "FCPort",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "FCPort", targets: ["FCPort"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FCPort",
            dependencies: [])
    ]
)
