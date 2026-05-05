import Foundation

public struct CodexPetManifest: Decodable, Equatable {
  public let id: String?
  public let displayName: String?
  public let description: String?
  public let spritesheetPath: String

  public init(
    id: String? = nil,
    displayName: String? = nil,
    description: String? = nil,
    spritesheetPath: String = "spritesheet.webp"
  ) {
    self.id = id?.trimmedNonEmpty
    self.displayName = displayName?.trimmedNonEmpty
    self.description = description?.trimmedNonEmpty
    self.spritesheetPath = spritesheetPath.trimmedNonEmpty ?? "spritesheet.webp"
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case displayName
    case description
    case spritesheetPath
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id)?.trimmedNonEmpty
    self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)?
      .trimmedNonEmpty
    self.description = try container.decodeIfPresent(String.self, forKey: .description)?
      .trimmedNonEmpty
    self.spritesheetPath =
      try container.decodeIfPresent(String.self, forKey: .spritesheetPath)?
      .trimmedNonEmpty ?? "spritesheet.webp"
  }
}

extension String {
  public var trimmedNonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
