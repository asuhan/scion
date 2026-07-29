// swift-tools-version:6.3
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import PackageDescription

let availabilityMacros: KeyValuePairs<String, String> = [
  "SwiftStdlib 5.0":  "macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2",
  "SwiftStdlib 5.1":  "macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0",
  "SwiftStdlib 5.6":  "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4",
  "SwiftStdlib 5.8":  "macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4",
  "SwiftStdlib 5.9":  "macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0",
  "SwiftStdlib 5.10": "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.1",
  "SwiftStdlib 6.0":  "macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0",
  "SwiftStdlib 6.1":  "macOS 15.4, iOS 18.4, watchOS 11.4, tvOS 18.4, visionOS 2.4",
  "SwiftStdlib 6.2":  "macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0",
  "SwiftStdlib 6.3":  "macOS 26.4, iOS 26.4, watchOS 26.4, tvOS 26.4, visionOS 26.4",
]

let _settings: [SwiftSetting] =
  availabilityMacros.map { name, value in
      .enableExperimentalFeature("AvailabilityMacro=\(name): \(value)")
  }

let package = Package(
  name: "swift-collections.Benchmarks",
  platforms: [.macOS(.v26), .iOS(.v26), .watchOS(.v26), .tvOS(.v26), .visionOS(.v26)],
  products: [
    .executable(name: "FormatterFixtures", targets: ["FormatterFixtures"]),
  ],
  dependencies: [
    .package(name: "swift-collections", path: "../../.."),
  ],
  targets: [
    .executableTarget(
      name: "FormatterFixtures",
      dependencies: [
        .product(name: "BasicContainers", package: "swift-collections"),
      ],
      path: "Sources",
      swiftSettings: _settings),
  ]
)
