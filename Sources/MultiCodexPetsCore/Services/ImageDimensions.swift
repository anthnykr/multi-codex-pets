import Foundation

public struct ImageDimensions: Equatable {
  public let width: Int
  public let height: Int
  public let mimeType: String

  public init(width: Int, height: Int, mimeType: String) {
    self.width = width
    self.height = height
    self.mimeType = mimeType
  }
}

public enum ImageDimensionsReader {
  public static func read(url: URL) throws -> ImageDimensions? {
    let data = try Data(contentsOf: url, options: [.mappedIfSafe])
    return read(data: data)
  }

  public static func read(data: Data) -> ImageDimensions? {
    readPNG(data: data) ?? readWebP(data: data)
  }

  private static func readPNG(data: Data) -> ImageDimensions? {
    guard data.count >= 24,
      data[0] == 137,
      String(data: data[1..<4], encoding: .ascii) == "PNG",
      data[4] == 13,
      data[5] == 10,
      data[6] == 26,
      data[7] == 10,
      String(data: data[12..<16], encoding: .ascii) == "IHDR"
    else {
      return nil
    }

    return ImageDimensions(
      width: data.readUInt32BE(at: 16),
      height: data.readUInt32BE(at: 20),
      mimeType: "image/png"
    )
  }

  private static func readWebP(data: Data) -> ImageDimensions? {
    guard data.count >= 20,
      String(data: data[0..<4], encoding: .ascii) == "RIFF",
      String(data: data[8..<12], encoding: .ascii) == "WEBP"
    else {
      return nil
    }

    var offset = 12
    while offset + 8 <= data.count {
      let chunkType = String(data: data[offset..<offset + 4], encoding: .ascii)
      let chunkSize = data.readUInt32LE(at: offset + 4)
      let payloadOffset = offset + 8
      guard payloadOffset + chunkSize <= data.count else {
        return nil
      }

      if let chunkType,
        let dimensions = readWebPChunk(
          type: chunkType,
          data: data,
          offset: payloadOffset,
          size: chunkSize
        )
      {
        return ImageDimensions(
          width: dimensions.width,
          height: dimensions.height,
          mimeType: "image/webp"
        )
      }

      offset = payloadOffset + chunkSize + (chunkSize % 2)
    }

    return nil
  }

  private static func readWebPChunk(
    type: String,
    data: Data,
    offset: Int,
    size: Int
  ) -> (width: Int, height: Int)? {
    switch type {
    case "VP8X":
      guard size >= 10 else { return nil }
      return (
        width: data.readUInt24LE(at: offset + 4) + 1,
        height: data.readUInt24LE(at: offset + 7) + 1
      )
    case "VP8L":
      guard size >= 5, data[offset] == 47 else { return nil }
      let packed = data.readUInt32LE(at: offset + 1)
      let mask = 16_383
      return (
        width: (packed & mask) + 1,
        height: ((packed >> 14) & mask) + 1
      )
    case "VP8 ":
      guard size >= 10,
        data[offset + 3] == 157,
        data[offset + 4] == 1,
        data[offset + 5] == 42
      else {
        return nil
      }
      return (
        width: data.readUInt16LE(at: offset + 6) & 16_383,
        height: data.readUInt16LE(at: offset + 8) & 16_383
      )
    default:
      return nil
    }
  }
}

extension Data {
  fileprivate subscript(bounds: Range<Int>) -> Data {
    subdata(in: bounds)
  }

  fileprivate func readUInt16LE(at offset: Int) -> Int {
    Int(self[offset]) | (Int(self[offset + 1]) << 8)
  }

  fileprivate func readUInt24LE(at offset: Int) -> Int {
    Int(self[offset]) | (Int(self[offset + 1]) << 8) | (Int(self[offset + 2]) << 16)
  }

  fileprivate func readUInt32BE(at offset: Int) -> Int {
    (Int(self[offset]) << 24)
      | (Int(self[offset + 1]) << 16)
      | (Int(self[offset + 2]) << 8)
      | Int(self[offset + 3])
  }

  fileprivate func readUInt32LE(at offset: Int) -> Int {
    Int(self[offset])
      | (Int(self[offset + 1]) << 8)
      | (Int(self[offset + 2]) << 16)
      | (Int(self[offset + 3]) << 24)
  }
}
