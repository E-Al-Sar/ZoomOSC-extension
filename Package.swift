// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ZoomOSC_extension",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ZoomOSC_extension",
            targets: ["ZoomOSC_extension"])
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/OSCKit", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "ZoomOSC_extension",
            dependencies: [
                .product(name: "OSCKit", package: "OSCKit")
            ],
            path: "ZoomOSC extension"
        ),
        .testTarget(
            name: "ZoomOSC_extensionTests",
            dependencies: ["ZoomOSC_extension"],
            path: "ZoomOSC extensionTests"
        ),
        .testTarget(
            name: "ZoomOSC_extensionUITests",
            dependencies: ["ZoomOSC_extension"],
            path: "ZoomOSC extensionUITests"
        )
    ]
) 