import MultiCodexPetsCore
import XCTest

final class AnimationTimelineTests: XCTestCase {
  func testAnimationRowsMatchCodexPetContract() {
    XCTAssertEqual(AnimationTimeline.frames(for: .idle).map(\.columnIndex), [0, 1, 2, 3, 4, 5])
    XCTAssertEqual(AnimationTimeline.frames(for: .runningRight).map(\.rowIndex).uniqued(), [1])
    XCTAssertEqual(AnimationTimeline.frames(for: .runningLeft).map(\.rowIndex).uniqued(), [2])
    XCTAssertEqual(AnimationTimeline.frames(for: .waving).count, 4)
    XCTAssertEqual(AnimationTimeline.frames(for: .jumping).count, 5)
    XCTAssertEqual(AnimationTimeline.frames(for: .failed).count, 8)
    XCTAssertEqual(AnimationTimeline.frames(for: .waiting).count, 6)
    XCTAssertEqual(AnimationTimeline.frames(for: .running).count, 6)
    XCTAssertEqual(AnimationTimeline.frames(for: .review).count, 6)
  }

  func testReducedMotionUsesFirstFrameOnly() {
    XCTAssertEqual(AnimationTimeline.frames(for: .review, reducedMotion: true).count, 1)
    XCTAssertEqual(AnimationTimeline.frames(for: .review, reducedMotion: true).first?.rowIndex, 8)
  }
}

extension Array where Element: Equatable {
  fileprivate func uniqued() -> [Element] {
    reduce(into: []) { result, element in
      if result.last != element {
        result.append(element)
      }
    }
  }
}
