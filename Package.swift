// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VMTranslator",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(
      name: "VMTranslator",
      targets: ["VMTranslator"]),
  ],
  dependencies: [
    .package(url: "https://github.com/EZabolotniy/files.git", from: "0.1.0"),
    .package(url: "https://github.com/EZabolotniy/string-utils", from: "0.1.1"),
  ],
  targets: [
    .executableTarget(
      name: "VMTranslator",
      dependencies: [
        .product(name: "Files", package: "Files"),
        .product(name: "RemoveComments", package: "string-utils"),
      ]
    )
  ]
)
