import Foundation

public enum AnimationState: String, CaseIterable, Identifiable {
  case idle
  case runningRight = "running-right"
  case runningLeft = "running-left"
  case waving
  case jumping
  case failed
  case waiting
  case running
  case review

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .idle:
      return "Idle"
    case .runningRight:
      return "Running Right"
    case .runningLeft:
      return "Running Left"
    case .waving:
      return "Waving"
    case .jumping:
      return "Jumping"
    case .failed:
      return "Failed"
    case .waiting:
      return "Waiting"
    case .running:
      return "Running"
    case .review:
      return "Review"
    }
  }
}

public struct AnimationFrame: Equatable {
  public let rowIndex: Int
  public let columnIndex: Int
  public let frameDurationMs: Int

  public init(rowIndex: Int, columnIndex: Int, frameDurationMs: Int) {
    self.rowIndex = rowIndex
    self.columnIndex = columnIndex
    self.frameDurationMs = frameDurationMs
  }
}

public enum AnimationTimeline {
  public static func frames(for state: AnimationState, reducedMotion: Bool = false)
    -> [AnimationFrame]
  {
    let frames = baseFrames(for: state)
    return reducedMotion ? Array(frames.prefix(1)) : frames
  }

  public static func baseFrames(for state: AnimationState) -> [AnimationFrame] {
    switch state {
    case .idle:
      return [
        .init(rowIndex: 0, columnIndex: 0, frameDurationMs: 280),
        .init(rowIndex: 0, columnIndex: 1, frameDurationMs: 110),
        .init(rowIndex: 0, columnIndex: 2, frameDurationMs: 110),
        .init(rowIndex: 0, columnIndex: 3, frameDurationMs: 140),
        .init(rowIndex: 0, columnIndex: 4, frameDurationMs: 140),
        .init(rowIndex: 0, columnIndex: 5, frameDurationMs: 320),
      ]
    case .runningRight:
      return repeatedRow(rowIndex: 1, count: 8, durationMs: 120, finalDurationMs: 220)
    case .runningLeft:
      return repeatedRow(rowIndex: 2, count: 8, durationMs: 120, finalDurationMs: 220)
    case .waving:
      return repeatedRow(rowIndex: 3, count: 4, durationMs: 140, finalDurationMs: 280)
    case .jumping:
      return repeatedRow(rowIndex: 4, count: 5, durationMs: 140, finalDurationMs: 280)
    case .failed:
      return repeatedRow(rowIndex: 5, count: 8, durationMs: 140, finalDurationMs: 240)
    case .waiting:
      return repeatedRow(rowIndex: 6, count: 6, durationMs: 150, finalDurationMs: 260)
    case .running:
      return repeatedRow(rowIndex: 7, count: 6, durationMs: 120, finalDurationMs: 220)
    case .review:
      return repeatedRow(rowIndex: 8, count: 6, durationMs: 150, finalDurationMs: 280)
    }
  }

  private static func repeatedRow(
    rowIndex: Int,
    count: Int,
    durationMs: Int,
    finalDurationMs: Int
  ) -> [AnimationFrame] {
    (0..<count).map { columnIndex in
      AnimationFrame(
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        frameDurationMs: columnIndex == count - 1 ? finalDurationMs : durationMs
      )
    }
  }
}
