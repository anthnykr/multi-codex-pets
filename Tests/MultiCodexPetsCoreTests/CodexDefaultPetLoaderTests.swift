import Foundation
import MultiCodexPetsCore
import XCTest

final class CodexDefaultPetLoaderTests: XCTestCase {
  private var temporaryDirectory: URL!
  private var codexAppURL: URL!

  override func setUpWithError() throws {
    temporaryDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    codexAppURL = temporaryDirectory.appendingPathComponent("Codex.app", isDirectory: true)
    try FileManager.default.createDirectory(
      at:
        codexAppURL
        .appendingPathComponent("Contents", isDirectory: true)
        .appendingPathComponent("Resources", isDirectory: true),
      withIntermediateDirectories: true
    )
  }

  override func tearDownWithError() throws {
    if let temporaryDirectory {
      try? FileManager.default.removeItem(at: temporaryDirectory)
    }
  }

  func testLoadsCodexDefaultSpritesheetsFromInstalledAppAsar() throws {
    let validSpritesheet = TestImageData.webP(width: 1_536, height: 1_872)
    let invalidSpritesheet = TestImageData.webP(width: 100, height: 100)

    try writeAsar(
      files: [
        "webview/assets/codex-spritesheet-v4-test.webp": validSpritesheet,
        "webview/assets/rocky-spritesheet-v4-test.webp": validSpritesheet,
        "webview/assets/dewey-spritesheet-v4-test.webp": invalidSpritesheet,
        "webview/assets/unknown-spritesheet-v4-test.webp": validSpritesheet,
      ]
    )

    let packages = CodexDefaultPetLoader(codexAppURL: codexAppURL).loadPackages()

    XCTAssertEqual(packages.map(\.id), ["codex-default-codex", "codex-default-rocky"])
    XCTAssertEqual(packages.map(\.displayName), ["Codex", "Rocky"])
    XCTAssertEqual(packages.map(\.source), [.codexDefault, .codexDefault])
    XCTAssertTrue(packages.allSatisfy { $0.spritesheetData == validSpritesheet })
  }

  func testReturnsEmptyWhenCodexAppAsarIsMissing() {
    let packages = CodexDefaultPetLoader(codexAppURL: codexAppURL).loadPackages()

    XCTAssertTrue(packages.isEmpty)
  }

  private func writeAsar(files: [String: Data]) throws {
    var offset = 0
    var asarFiles: [String: Any] = [:]
    var payload = Data()

    for path in files.keys.sorted() {
      guard let data = files[path] else { continue }
      insertAsarFile(
        path: path,
        size: data.count,
        offset: offset,
        into: &asarFiles
      )
      payload.append(data)
      offset += data.count
    }

    let header = ["files": asarFiles]
    let headerData = try JSONSerialization.data(
      withJSONObject: header,
      options: [.sortedKeys]
    )

    var asar = Data(repeating: 0, count: 16)
    asar.writeUInt32LEForTest(4, at: 0)
    asar.writeUInt32LEForTest(headerData.count + 9, at: 4)
    asar.writeUInt32LEForTest(headerData.count + 5, at: 8)
    asar.writeUInt32LEForTest(headerData.count + 1, at: 12)
    asar.append(headerData)
    asar.append(0)
    asar.append(payload)

    try asar.write(
      to:
        codexAppURL
        .appendingPathComponent("Contents", isDirectory: true)
        .appendingPathComponent("Resources", isDirectory: true)
        .appendingPathComponent("app.asar")
    )
  }

  private func insertAsarFile(
    path: String,
    size: Int,
    offset: Int,
    into files: inout [String: Any]
  ) {
    var components = path.split(separator: "/").map(String.init)
    let fileName = components.removeLast()
    var current = files
    insertAsarFile(
      components: components,
      fileName: fileName,
      size: size,
      offset: offset,
      into: &current
    )
    files = current
  }

  private func insertAsarFile(
    components: [String],
    fileName: String,
    size: Int,
    offset: Int,
    into files: inout [String: Any]
  ) {
    guard let component = components.first else {
      files[fileName] = ["size": size, "offset": "\(offset)"]
      return
    }

    var node = files[component] as? [String: Any] ?? [:]
    var childFiles = node["files"] as? [String: Any] ?? [:]
    insertAsarFile(
      components: Array(components.dropFirst()),
      fileName: fileName,
      size: size,
      offset: offset,
      into: &childFiles
    )
    node["files"] = childFiles
    files[component] = node
  }
}

extension Data {
  fileprivate mutating func writeUInt32LEForTest(_ value: Int, at offset: Int) {
    self[offset] = UInt8(value & 0xff)
    self[offset + 1] = UInt8((value >> 8) & 0xff)
    self[offset + 2] = UInt8((value >> 16) & 0xff)
    self[offset + 3] = UInt8((value >> 24) & 0xff)
  }
}
