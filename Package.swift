// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MRGPagerController",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "MRGPagerController",
            targets: ["MRGPagerController"]
        ),
    ],
    targets: [
        .target(
            name: "MRGPagerController",
            publicHeadersPath: "include"
        ),
    ]
)
