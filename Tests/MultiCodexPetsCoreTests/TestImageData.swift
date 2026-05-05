import Foundation

enum TestImageData {
  static func png(width: Int, height: Int) -> Data {
    var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
    data.append(contentsOf: [0, 0, 0, 13])
    data.append(ascii: "IHDR")
    data.appendUInt32BE(width)
    data.appendUInt32BE(height)
    return data
  }

  static func webP(width: Int, height: Int) -> Data {
    var payload = Data(repeating: 0, count: 10)
    payload.writeUInt24LE(width - 1, at: 4)
    payload.writeUInt24LE(height - 1, at: 7)

    var data = Data()
    data.append(ascii: "RIFF")
    data.appendUInt32LE(4 + 8 + payload.count)
    data.append(ascii: "WEBP")
    data.append(ascii: "VP8X")
    data.appendUInt32LE(payload.count)
    data.append(payload)
    return data
  }
}

extension Data {
  fileprivate mutating func append(ascii: String) {
    append(ascii.data(using: .ascii)!)
  }

  fileprivate mutating func appendUInt32BE(_ value: Int) {
    append(UInt8((value >> 24) & 0xff))
    append(UInt8((value >> 16) & 0xff))
    append(UInt8((value >> 8) & 0xff))
    append(UInt8(value & 0xff))
  }

  fileprivate mutating func appendUInt32LE(_ value: Int) {
    append(UInt8(value & 0xff))
    append(UInt8((value >> 8) & 0xff))
    append(UInt8((value >> 16) & 0xff))
    append(UInt8((value >> 24) & 0xff))
  }

  fileprivate mutating func writeUInt24LE(_ value: Int, at offset: Int) {
    self[offset] = UInt8(value & 0xff)
    self[offset + 1] = UInt8((value >> 8) & 0xff)
    self[offset + 2] = UInt8((value >> 16) & 0xff)
  }
}
