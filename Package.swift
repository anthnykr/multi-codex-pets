// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "MultiCodexPets",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "MultiCodexPets", targets: ["MultiCodexPets"]),
    .library(name: "MultiCodexPetsCore", targets: ["MultiCodexPetsCore"]),
  ],
  targets: [
    .target(name: "MultiCodexPetsCore"),
    .executableTarget(
      name: "MultiCodexPets",
      dependencies: ["MultiCodexPetsCore"]
    ),
    .testTarget(
      name: "MultiCodexPetsCoreTests",
      dependencies: ["MultiCodexPetsCore"]
    ),
  ]
)
