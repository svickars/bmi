// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BMI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BMI", targets: ["BMI"])
    ],
    targets: [
        .target(
            name: "BMI",
            path: "BMI"
        )
    ]
)
