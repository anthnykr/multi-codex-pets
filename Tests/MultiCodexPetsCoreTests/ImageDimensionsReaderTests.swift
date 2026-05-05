import Foundation
import MultiCodexPetsCore
import XCTest

final class ImageDimensionsReaderTests: XCTestCase {
  func testReadsPngDimensions() {
    let data = TestImageData.png(width: 1_536, height: 1_872)
    XCTAssertEqual(
      ImageDimensionsReader.read(data: data),
      ImageDimensions(width: 1_536, height: 1_872, mimeType: "image/png")
    )
  }

  func testReadsWebPDimensions() {
    let data = TestImageData.webP(width: 1_536, height: 1_872)
    XCTAssertEqual(
      ImageDimensionsReader.read(data: data),
      ImageDimensions(width: 1_536, height: 1_872, mimeType: "image/webp")
    )
  }
}
