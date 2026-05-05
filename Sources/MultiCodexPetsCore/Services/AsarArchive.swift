import Foundation

enum AsarArchiveError: Error, Equatable {
  case invalidHeader
  case invalidJSON
}

struct AsarArchive {
  private let data: Data
  private let dataStartOffset: Int
  private let root: [String: Any]

  init(url: URL) throws {
    self.data = try Data(contentsOf: url, options: [.mappedIfSafe])

    guard data.count >= 16 else {
      throw AsarArchiveError.invalidHeader
    }

    let headerSize = data.readAsarUInt32LE(at: 12)
    let headerStartOffset = 16
    let headerEndOffset = headerStartOffset + headerSize
    guard headerSize > 0, data.count >= headerEndOffset else {
      throw AsarArchiveError.invalidHeader
    }

    var headerJSONEndOffset = headerEndOffset
    while headerJSONEndOffset > headerStartOffset && data[headerJSONEndOffset - 1] == 0 {
      headerJSONEndOffset -= 1
    }

    var dataStartOffset = headerEndOffset
    while dataStartOffset < data.count && data[dataStartOffset] == 0 {
      dataStartOffset += 1
    }

    let headerData = data.subdata(in: headerStartOffset..<headerJSONEndOffset)
    guard
      let root = try JSONSerialization.jsonObject(with: headerData) as? [String: Any]
    else {
      throw AsarArchiveError.invalidJSON
    }

    self.dataStartOffset = dataStartOffset
    self.root = root
  }

  var filePaths: [String] {
    guard let files = root["files"] as? [String: Any] else { return [] }
    return collectFilePaths(in: files, prefix: "")
  }

  func readFile(path: String) -> Data? {
    guard
      let node = node(for: path),
      node["files"] == nil,
      let size = node["size"] as? Int,
      let offsetString = node["offset"] as? String,
      let offset = Int(offsetString)
    else {
      return nil
    }

    let start = dataStartOffset + offset
    let end = start + size
    guard start >= dataStartOffset, end <= data.count else {
      return nil
    }

    return data.subdata(in: start..<end)
  }

  private func collectFilePaths(in files: [String: Any], prefix: String) -> [String] {
    files.flatMap { name, rawNode -> [String] in
      let path = prefix.isEmpty ? name : "\(prefix)/\(name)"
      guard let node = rawNode as? [String: Any] else { return [] }

      if let childFiles = node["files"] as? [String: Any] {
        return collectFilePaths(in: childFiles, prefix: path)
      }

      return [path]
    }
  }

  private func node(for path: String) -> [String: Any]? {
    var currentFiles = root["files"] as? [String: Any]
    var currentNode: [String: Any]?

    for component in path.split(separator: "/").map(String.init) {
      guard let node = currentFiles?[component] as? [String: Any] else {
        return nil
      }

      currentNode = node
      currentFiles = node["files"] as? [String: Any]
    }

    return currentNode
  }
}

extension Data {
  fileprivate func readAsarUInt32LE(at offset: Int) -> Int {
    Int(self[offset])
      | (Int(self[offset + 1]) << 8)
      | (Int(self[offset + 2]) << 16)
      | (Int(self[offset + 3]) << 24)
  }
}
