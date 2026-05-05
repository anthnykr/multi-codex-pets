import AppKit
import MultiCodexPetsCore

final class PetSpriteView: NSView {
  private let image: NSImage?
  private var frames: [AnimationFrame] = []
  private var frameIndex = 0
  private var frameTimer: Timer?
  private var trackingAreaRef: NSTrackingArea?
  private var dragStartMouseLocation: NSPoint?
  private var dragStartWindowOrigin: NSPoint?
  private var transientState: AnimationState?

  let pet: PetPackage

  var animationState: AnimationState {
    didSet {
      guard transientState == nil else { return }
      restartAnimation(for: animationState)
    }
  }

  init(pet: PetPackage, animationState: AnimationState) {
    self.pet = pet
    self.animationState = animationState
    if let spritesheetData = pet.spritesheetData {
      self.image = NSImage(data: spritesheetData)
    } else {
      self.image = NSImage(contentsOf: pet.spritesheetURL)
    }
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    restartAnimation(for: animationState)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  deinit {
    frameTimer?.invalidate()
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
    true
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingAreaRef {
      removeTrackingArea(trackingAreaRef)
    }

    let trackingArea = NSTrackingArea(
      rect: bounds,
      options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
      owner: self
    )
    addTrackingArea(trackingArea)
    trackingAreaRef = trackingArea
  }

  override func mouseEntered(with event: NSEvent) {
    guard transientState == nil else { return }
    setTransientState(.jumping)
  }

  override func mouseExited(with event: NSEvent) {
    if transientState == .jumping {
      setTransientState(nil)
    }
  }

  override func mouseDown(with event: NSEvent) {
    dragStartMouseLocation = NSEvent.mouseLocation
    dragStartWindowOrigin = window?.frame.origin
  }

  override func mouseDragged(with event: NSEvent) {
    guard let window,
      let dragStartMouseLocation,
      let dragStartWindowOrigin
    else {
      return
    }

    let currentLocation = NSEvent.mouseLocation
    let deltaX = currentLocation.x - dragStartMouseLocation.x
    let deltaY = currentLocation.y - dragStartMouseLocation.y
    window.setFrameOrigin(
      NSPoint(
        x: dragStartWindowOrigin.x + deltaX,
        y: dragStartWindowOrigin.y + deltaY
      ))

    if deltaX > 4 {
      setTransientState(.runningRight)
    } else if deltaX < -4 {
      setTransientState(.runningLeft)
    }
  }

  override func mouseUp(with event: NSEvent) {
    dragStartMouseLocation = nil
    dragStartWindowOrigin = nil
    setTransientState(nil)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    guard let image,
      !frames.isEmpty
    else {
      return
    }

    let frame = frames[min(frameIndex, frames.count - 1)]
    let sourceRect = NSRect(
      x: CGFloat(frame.columnIndex * PetAtlas.cellWidth),
      y: CGFloat(PetAtlas.height - ((frame.rowIndex + 1) * PetAtlas.cellHeight)),
      width: CGFloat(PetAtlas.cellWidth),
      height: CGFloat(PetAtlas.cellHeight)
    )

    NSGraphicsContext.current?.imageInterpolation = .none
    image.draw(
      in: bounds,
      from: sourceRect,
      operation: .sourceOver,
      fraction: 1,
      respectFlipped: false,
      hints: nil
    )
  }

  private func setTransientState(_ state: AnimationState?) {
    guard transientState != state else { return }
    transientState = state
    restartAnimation(for: state ?? animationState)
  }

  private func restartAnimation(for state: AnimationState) {
    frameTimer?.invalidate()
    frameIndex = 0
    frames = AnimationTimeline.frames(
      for: state,
      reducedMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    )
    needsDisplay = true
    scheduleNextFrame()
  }

  private func scheduleNextFrame() {
    guard frames.count > 1 else { return }

    let duration = TimeInterval(frames[frameIndex].frameDurationMs) / 1000
    let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
      self?.advanceFrame()
    }
    RunLoop.main.add(timer, forMode: .common)
    frameTimer = timer
  }

  private func advanceFrame() {
    guard !frames.isEmpty else { return }

    frameIndex = (frameIndex + 1) % frames.count
    needsDisplay = true
    scheduleNextFrame()
  }
}
