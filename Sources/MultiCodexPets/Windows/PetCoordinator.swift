import AppKit
import MultiCodexPetsCore

final class PetCoordinator {
  private var windowControllersByPetID: [String: PetWindowController] = [:]
  private var visiblePetIDs: [String] = []
  private var rememberedFramesByPetID: [String: NSRect] = [:]

  var isShowingPets: Bool {
    !visiblePetIDs.isEmpty
  }

  func showPets(
    _ packages: [PetPackage],
    state: AnimationState,
    scale: Double
  ) {
    guard !packages.isEmpty else {
      hidePets()
      return
    }

    let requestedPetIDs = Set(packages.map(\.id))
    let removedPetIDs = visiblePetIDs.filter { !requestedPetIDs.contains($0) }
    for petID in removedPetIDs {
      closeController(forPetID: petID)
    }

    var nextVisiblePetIDs: [String] = []
    for (index, package) in packages.enumerated() {
      let controller =
        existingController(for: package)
        ?? makeController(for: package, index: index, state: state, scale: scale)
      controller.setAnimationState(state)
      controller.setScale(scale)
      controller.show()
      windowControllersByPetID[package.id] = controller
      nextVisiblePetIDs.append(package.id)
    }

    visiblePetIDs = nextVisiblePetIDs
  }

  func hidePets() {
    for petID in visiblePetIDs {
      closeController(forPetID: petID)
    }
    visiblePetIDs.removeAll()
  }

  func setAnimationState(_ state: AnimationState) {
    for controller in visibleControllers {
      controller.setAnimationState(state)
    }
  }

  func setScale(_ scale: Double) {
    for controller in visibleControllers {
      controller.setScale(scale)
    }
  }

  private var visibleControllers: [PetWindowController] {
    visiblePetIDs.compactMap { windowControllersByPetID[$0] }
  }

  private func existingController(for package: PetPackage) -> PetWindowController? {
    guard let controller = windowControllersByPetID[package.id] else {
      return nil
    }

    guard controller.pet == package else {
      closeController(forPetID: package.id)
      return nil
    }

    return controller
  }

  private func makeController(
    for package: PetPackage,
    index: Int,
    state: AnimationState,
    scale: Double
  ) -> PetWindowController {
    PetWindowController(
      pet: package,
      initialFrame: initialFrame(forPetID: package.id, index: index, scale: scale),
      animationState: state,
      scale: scale
    )
  }

  private func closeController(forPetID petID: String) {
    guard let controller = windowControllersByPetID.removeValue(forKey: petID) else {
      return
    }

    if let frame = controller.currentFrame {
      rememberedFramesByPetID[petID] = frame
    }
    controller.close()
  }

  private func initialFrame(forPetID petID: String, index: Int, scale: Double) -> NSRect {
    if let rememberedFrame = rememberedFramesByPetID[petID] {
      return NSRect(
        origin: rememberedFrame.origin,
        size: PetWindowController.windowSize(scale: scale)
      )
    }

    return defaultInitialFrame(index: index, scale: scale)
  }

  private func defaultInitialFrame(index: Int, scale: Double) -> NSRect {
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
