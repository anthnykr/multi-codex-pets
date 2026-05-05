import AppKit
import MultiCodexPetsCore

final class PetCoordinator {
  private var windowControllers: [PetWindowController] = []
  private var currentState: AnimationState = .idle
  private var currentScale: Double = 1

  var isShowingPets: Bool {
    !windowControllers.isEmpty
  }

  func showPets(
    _ packages: [PetPackage],
    state: AnimationState,
    scale: Double
  ) {
    hidePets()

    guard !packages.isEmpty else { return }

    currentState = state
    currentScale = scale

    windowControllers = packages.enumerated().map { index, package in
      let controller = PetWindowController(
        pet: package,
        initialFrame: initialFrame(index: index, scale: scale),
        animationState: state,
        scale: scale
      )
      controller.show()
      return controller
    }
  }

  func hidePets() {
    for controller in windowControllers {
      controller.close()
    }
    windowControllers.removeAll()
  }

  func setAnimationState(_ state: AnimationState) {
    currentState = state
    for controller in windowControllers {
      controller.setAnimationState(state)
    }
  }

  func setScale(_ scale: Double) {
    currentScale = scale
    for controller in windowControllers {
      controller.setScale(scale)
    }
  }

  private func initialFrame(index: Int, scale: Double) -> NSRect {
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let size = PetWindowController.windowSize(scale: scale)
    let horizontalStep = size.width + 22
    let rowOffset = CGFloat(index % 2) * 32
    let originX = max(
      screen.minX + 24,
      screen.maxX - size.width - 80 - CGFloat(index) * horizontalStep
    )
    let originY = min(
      screen.maxY - size.height - 24,
      screen.minY + 96 + rowOffset
    )

    return NSRect(origin: NSPoint(x: originX, y: originY), size: size)
  }
}
