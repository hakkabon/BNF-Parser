// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BNF",
    products: [
        .library(name: "BNF", targets: ["BNF"]),
        .executable(name: "ebnf", targets: ["ebnf"]),
    ],
    dependencies: [
        .package(name: "Files", url: "https://github.com/johnsundell/files.git", from: "2.2.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(name: "Tokenizer", url: "https://github.com/hakkabon/tokenizer", from: "1.0.2"),
    ],
    targets: [
        .target(name: "BNF", dependencies: ["Tokenizer","Files"]),
        .target(name: "ebnf", dependencies: ["BNF", "Files",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .testTarget(name: "BNFTests", dependencies: ["BNF"]),
    ]
)
