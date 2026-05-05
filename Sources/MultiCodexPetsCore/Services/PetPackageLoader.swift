import Foundation

public struct PetPackageLoader {
  public let fileManager: FileManager
  public let codexHome: URL

  public init(
    fileManager: FileManager = .default,
    codexHome: URL = PetPackageLoader.defaultCodexHome()
  ) {
    self.fileManager = fileManager
    self.codexHome = codexHome
  }

  public var petsDirectory: URL {
    codexHome.appendingPathComponent("pets", isDirectory: true)
  }

  public static func defaultCodexHome() -> URL {
    if let override = ProcessInfo.processInfo.environment["CODEX_HOME"]?.trimmedNonEmpty {
      return URL(fileURLWithPath: override, isDirectory: true)
    }

    return fileManagerHomeDirectory()
      .appendingPathComponent(".codex", isDirectory: true)
  }

  public func ensurePetsDirectoryExists() throws {
    try fileManager.createDirectory(
      at: petsDirectory,
      withIntermediateDirectories: true
    )
  }

  public func loadPackages() -> [PetPackage] {
    do {
      try ensurePetsDirectoryExists()
      let packageDirectories = try fileManager.contentsOfDirectory(
        at: petsDirectory,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )

      return
        packageDirectories
        .filter { $0.isDirectory(fileManager: fileManager) }
        .compactMap(loadPackage(directory:))
        .sorted {
          $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    } catch {
      return []
    }
  }

  private func loadPackage(directory: URL) -> PetPackage? {
    let manifestURL = directory.appendingPathComponent("pet.json")
    guard let manifestData = try? Data(contentsOf: manifestURL),
      let manifest = try? JSONDecoder().decode(CodexPetManifest.self, from: manifestData),
      let spritesheetURL = resolveSpritesheetURL(manifest.spritesheetPath, in: directory),
      isValidPetSpritesheet(spritesheetURL)
    else {
      return nil
    }

    let folderName = directory.lastPathComponent
    let displayName = manifest.displayName ?? manifest.id ?? folderName

    return PetPackage(
      id: folderName,
      folderName: folderName,
      displayName: displayName,
      description: manifest.description,
      spritesheetURL: spritesheetURL,
      packageDirectory: directory
    )
  }

  private func resolveSpritesheetURL(_ path: String, in directory: URL) -> URL? {
    guard !path.hasPrefix("/"),
      !path.contains("\0")
    else {
      return nil
    }

    let base = directory.standardizedFileURL
    let resolved = base.appendingPathComponent(path).standardizedFileURL
    let basePath = base.path
    let resolvedPath = resolved.path

    guard resolvedPath == basePath || resolvedPath.hasPrefix(basePath + "/") else {
      return nil
    }

    return resolved
  }

  private func isValidPetSpritesheet(_ url: URL) -> Bool {
    guard let dimensions = try? ImageDimensionsReader.read(url: url) else {
      return false
    }

    return dimensions.width == PetAtlas.width
      && dimensions.height == PetAtlas.height
  }
}

private func fileManagerHomeDirectory() -> URL {
  FileManager.default.homeDirectoryForCurrentUser
}

extension URL {
  fileprivate func isDirectory(fileManager: FileManager) -> Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
  }
}
