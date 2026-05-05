import Foundation

public struct CodexDefaultPetLoader {
  public let fileManager: FileManager
  public let codexAppURL: URL

  public init(
    fileManager: FileManager = .default,
    codexAppURL: URL = CodexDefaultPetLoader.defaultCodexAppURL()
  ) {
    self.fileManager = fileManager
    self.codexAppURL = codexAppURL
  }

  public static func defaultCodexAppURL() -> URL {
    if let override = ProcessInfo.processInfo.environment["CODEX_APP_PATH"]?.trimmedNonEmpty {
      return URL(fileURLWithPath: override, isDirectory: true)
    }

    return URL(fileURLWithPath: "/Applications/Codex.app", isDirectory: true)
  }

  public func loadPackages() -> [PetPackage] {
    let asarURL =
      codexAppURL
      .appendingPathComponent("Contents", isDirectory: true)
      .appendingPathComponent("Resources", isDirectory: true)
      .appendingPathComponent("app.asar")

    guard fileManager.fileExists(atPath: asarURL.path),
      let archive = try? AsarArchive(url: asarURL)
    else {
      return []
    }

    return
      archive.filePaths
      .compactMap { path -> CodexDefaultPetAsset? in
        guard let metadata = CodexDefaultPetAsset(path: path),
          let spritesheetData = archive.readFile(path: path),
          isValidPetSpritesheet(spritesheetData)
        else {
          return nil
        }

        return metadata.withSpritesheetData(spritesheetData)
      }
      .sorted { $0.sortOrder < $1.sortOrder }
      .map { asset in
        PetPackage(
          id: "codex-default-\(asset.id)",
          folderName: asset.id,
          displayName: asset.displayName,
          description: asset.description,
          spritesheetURL: asarURL,
          spritesheetData: asset.spritesheetData,
          packageDirectory: codexAppURL,
          source: .codexDefault
        )
      }
  }

  private func isValidPetSpritesheet(_ data: Data) -> Bool {
    guard let dimensions = ImageDimensionsReader.read(data: data) else {
      return false
    }

    return dimensions.width == PetAtlas.width
      && dimensions.height == PetAtlas.height
  }
}

private struct CodexDefaultPetAsset {
  let id: String
  let displayName: String
  let description: String
  let sortOrder: Int
  let spritesheetData: Data

  init?(path: String) {
    guard path.hasPrefix("webview/assets/"),
      path.hasSuffix(".webp"),
      let fileName = path.split(separator: "/").last.map(String.init),
      let range = fileName.range(of: "-spritesheet-v4-")
    else {
      return nil
    }

    let id = String(fileName[..<range.lowerBound])
    guard let metadata = Self.metadata[id] else {
      return nil
    }

    self.id = id
    self.displayName = metadata.displayName
    self.description = metadata.description
    self.sortOrder = metadata.sortOrder
    self.spritesheetData = Data()
  }

  private init(
    id: String,
    displayName: String,
    description: String,
    sortOrder: Int,
    spritesheetData: Data
  ) {
    self.id = id
    self.displayName = displayName
    self.description = description
    self.sortOrder = sortOrder
    self.spritesheetData = spritesheetData
  }

  func withSpritesheetData(_ spritesheetData: Data) -> Self {
    Self(
      id: id,
      displayName: displayName,
      description: description,
      sortOrder: sortOrder,
      spritesheetData: spritesheetData
    )
  }

  private static let metadata:
    [String: (displayName: String, description: String, sortOrder: Int)] =
      [
        "codex": ("Codex", "The original Codex companion.", 0),
        "dewey": ("Dewey", "A tidy duck for calm workspace days.", 1),
        "fireball": ("Fireball", "Hot path energy for fast iteration.", 2),
        "rocky": ("Rocky", "A steady rock when the diff gets large.", 3),
        "seedy": ("Seedy", "Small green shoots for new ideas.", 4),
        "stacky": ("Stacky", "A balanced stack for deep work.", 5),
        "bsod": ("BSOD", "A tiny blue-screen companion.", 6),
        "null-signal": ("Null Signal", "Quiet signal from the void.", 7),
      ]
}
