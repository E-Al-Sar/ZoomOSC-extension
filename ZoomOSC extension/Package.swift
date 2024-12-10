// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ZoomOSC-extension",
    platforms: [
        .macOS(.v11)
    ],
    dependencies: [
        .package(url: "https://github.com/cocoaasyncSocket/CocoaAsyncSocket.git", from: "7.6.5"),
        .package(url: "https://github.com/natestedman/SwiftASCII.git", from: "1.0.0"),
        .package(url: "https://github.com/orchetect/OSCKit", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "ZoomOSCExtension",
            dependencies: [
                "CocoaAsyncSocket",
                "SwiftASCII",
                .product(name: "OSCKit", package: "OSCKit"),
                .product(name: "OSCKitCore", package: "OSCKit")
            ],
            path: "Sources"
        )
    ]
) 