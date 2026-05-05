import Foundation

public enum PetSource: String, Equatable {
  case codexDefault
  case custom
}

public struct PetPackage: Equatable, Identifiable {
  public let id: String
  public let folderName: String
  public let displayName: String
  public let description: String?
  public let spritesheetURL: URL
  public let spritesheetData: Data?
  public let packageDirectory: URL
  public let source: PetSource

  public init(
    id: String,
    folderName: String,
    displayName: String,
    description: String?,
    spritesheetURL: URL,
    spritesheetData: Data? = nil,
    packageDirectory: URL,
    source: PetSource = .custom
  ) {
    self.id = id
    self.folderName = folderName
    self.displayName = displayName
    self.description = description
    self.spritesheetURL = spritesheetURL
    self.spritesheetData = spritesheetData
    self.packageDirectory = packageDirectory
    self.source = source
  }
}
