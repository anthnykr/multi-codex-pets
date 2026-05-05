import Foundation
import MultiCodexPetsCore
import XCTest

final class PetPackageLoaderTests: XCTestCase {
  private var temporaryDirectory: URL!

  override func setUpWithError() throws {
    temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
      at: temporaryDirectory,
      withIntermediateDirectories: true
    )
  }

  override func tearDownWithError() throws {
    if let temporaryDirectory {
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }
  }

  func testLoadsValidPetPackage() throws {
    try writePet(
      folderName: "alpha",
      manifest: """
        {
          "id": "alpha",
          "displayName": "Alpha",
          "description": "A test pet.",
          "spritesheetPath": "spritesheet.webp"
        }
        """
    )

    let packages = PetPackageLoader(codexHome: temporaryDirectory).loadPackages()

    XCTAssertEqual(packages.count, 1)
    XCTAssertEqual(packages[0].id, "alpha")
    XCTAssertEqual(packages[0].displayName, "Alpha")
    XCTAssertEqual(packages[0].description, "A test pet.")
    XCTAssertEqual(packages[0].source, .custom)
  }

  func testRejectsSpritesheetPathOutsidePackageDirectory() throws {
    try writePet(
      folderName: "escape",
      manifest: """
        {
          "displayName": "Escape",
          "spritesheetPath": "../spritesheet.webp"
        }
        """
    )

    let packages = PetPackageLoader(codexHome: temporaryDirectory).loadPackages()

    XCTAssertTrue(packages.isEmpty)
  }

  private func writePet(folderName: String, manifest: String) throws {
    let packageDirectory =
      temporaryDirectory
      .appendingPathComponent("pets", isDirectory: true)
      .appendingPathComponent(folderName, isDirectory: true)
    try FileManager.default.createDirectory(
      at: packageDirectory,
      withIntermediateDirectories: true
    )
    try manifest.write(
      to: packageDirectory.appendingPathComponent("pet.json"),
      atomically: true,
      encoding: .utf8
    )
    try TestImageData.webP(width: 1_536, height: 1_872)
      .write(to: packageDirectory.appendingPathComponent("spritesheet.webp"))
  }
}
