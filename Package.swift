// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Inkable",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library( name: "Inkable", targets: ["Inkable"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/adamwulf/PerformanceBezier.git", from: "1.3.0"),
        .package(url: "https://github.com/adamwulf/ClippingBezier.git", from: "1.2.0"),
        .package(url: "https://github.com/adamwulf/SwiftToolbox.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Inkable",
            dependencies: ["PerformanceBezier", "ClippingBezier", "SwiftToolbox"],
            exclude: ["External/OrderedSet/LICENSE", "External/ColorCodable/LICENSE"]),
        .testTarget(
            name: "InkableTests",
            dependencies: ["Inkable"],
            resources: [.copy("events.json"),
                        .copy("pencil-antigrain.json"),
                        .copy("pencil-antigrain2.json"),
                        .copy("pencil-error.json"),
                        .copy("unknown-polyline-index.json")])
    ]
)
