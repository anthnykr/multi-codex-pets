import AppKit
import MultiCodexPetsCore

final class PetWindowController: NSWindowController {
  private let petView: PetSpriteView

  var pet: PetPackage {
    petView.pet
  }

  var currentFrame: NSRect? {
    window?.frame
  }

  init(
    pet: PetPackage,
    initialFrame: NSRect,
    animationState: AnimationState,
    scale: Double
  ) {
    self.petView = PetSpriteView(pet: pet, animationState: animationState)

    let window = NSWindow(
      contentRect: initialFrame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.isReleasedWhenClosed = false
    window.backgroundColor = .clear
    window.isOpaque = false
    window.hasShadow = false
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.acceptsMouseMovedEvents = true
    window.contentView = petView

    super.init(window: window)
    setScale(scale)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  static func windowSize(scale: Double) -> NSSize {
    let baseWidth: CGFloat = 80
    let baseHeight = baseWidth * CGFloat(PetAtlas.cellHeight) / CGFloat(PetAtlas.cellWidth)
    return NSSize(width: baseWidth * scale, height: baseHeight * scale)
  }

  func show() {
    showWindow(nil)
    window?.orderFrontRegardless()
  }

  func setAnimationState(_ state: AnimationState) {
    petView.animationState = state
  }

  func setScale(_ scale: Double) {
    guard let window else { return }

    let oldFrame = window.frame
    let newSize = Self.windowSize(scale: scale)
    let newFrame = NSRect(origin: oldFrame.origin, size: newSize)
    window.setFrame(newFrame, display: true)
    petView.frame = NSRect(origin: .zero, size: newSize)
  }
}
