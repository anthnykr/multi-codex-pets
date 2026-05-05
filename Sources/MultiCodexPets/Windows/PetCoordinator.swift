import AppKit
import MultiCodexPetsCore

final class PetCoordinator {
  private var windowControllersByPetID: [String: PetWindowController] = [:]
  private var visiblePetIDs: [String] = []
  private var rememberedFramesByPetID: [String: NSRect] = [:]
  private var walkingMotionsByPetID: [String: WalkingMotion] = [:]
  private var walkingTimer: Timer?
  private var lastWalkingTickAt: Date?
  private var walksAround = false

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
      controller.setScale(scale)
      let now = Date()
      let motion = walkingMotion(
        forPetID: package.id,
        frame: controller.currentFrame,
        now: now
      )
      controller.setAnimationState(
        walksAround ? walkingAnimationState(for: motion.velocity) : state,
        randomizeInitialFrame: walksAround
      )
      controller.show()
      windowControllersByPetID[package.id] = controller
      nextVisiblePetIDs.append(package.id)
    }

    visiblePetIDs = nextVisiblePetIDs
    updateWalkingTimer()
  }

  func hidePets() {
    for petID in visiblePetIDs {
      closeController(forPetID: petID)
    }
    visiblePetIDs.removeAll()
    updateWalkingTimer()
  }

  func setAnimationState(_ state: AnimationState) {
    guard !walksAround else { return }

    for controller in visibleControllers {
      controller.setAnimationState(state)
    }
  }

  func setScale(_ scale: Double) {
    for controller in visibleControllers {
      controller.setScale(scale)
    }
  }

  func setWalksAround(_ enabled: Bool, baseState: AnimationState) {
    walksAround = enabled

    if enabled {
      let now = Date()
      for petID in visiblePetIDs {
        let motion = walkingMotion(
          forPetID: petID,
          frame: windowControllersByPetID[petID]?.currentFrame,
          now: now
        )
        windowControllersByPetID[petID]?.setAnimationState(
          walkingAnimationState(for: motion.velocity),
          randomizeInitialFrame: true
        )
      }
    } else {
      for controller in visibleControllers {
        controller.setAnimationState(baseState)
      }
    }

    updateWalkingTimer()
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
    walkingMotionsByPetID.removeValue(forKey: petID)
    controller.close()
  }

  private func updateWalkingTimer() {
    guard walksAround, !visiblePetIDs.isEmpty else {
      walkingTimer?.invalidate()
      walkingTimer = nil
      lastWalkingTickAt = nil
      return
    }

    guard walkingTimer == nil else { return }

    lastWalkingTickAt = Date()
    let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
      self?.moveWalkingPets()
    }
    RunLoop.main.add(timer, forMode: .common)
    walkingTimer = timer
  }

  private func moveWalkingPets() {
    let now = Date()
    let elapsed = min(now.timeIntervalSince(lastWalkingTickAt ?? now), 0.1)
    lastWalkingTickAt = now

    guard elapsed > 0 else { return }

    for petID in visiblePetIDs {
      guard let controller = windowControllersByPetID[petID],
        !controller.isUserDragging,
        let frame = controller.currentFrame
      else {
        continue
      }

      let screenFrame = screenFrame(containing: frame)
      var motion = walkingMotion(
        forPetID: petID,
        frame: frame,
        now: now
      )
      if now >= motion.retargetAt || frame.origin.distance(to: motion.targetOrigin) < 32 {
        motion = randomWalkingMotion(
          now: now,
          frame: frame,
          screenFrame: screenFrame
        )
      } else {
        motion.velocity = velocity(from: frame.origin, to: motion.targetOrigin, speed: motion.speed)
      }

      let movement = walkingMovement(
        frame: frame,
        velocity: motion.velocity,
        elapsed: elapsed,
        screenFrame: screenFrame
      )

      if movement.didBounce {
        motion = randomWalkingMotion(
          now: now,
          frame: NSRect(origin: movement.origin, size: frame.size),
          screenFrame: screenFrame
        )
      } else {
        motion.velocity = movement.velocity
      }
      walkingMotionsByPetID[petID] = motion
      controller.setFrameOrigin(movement.origin)
      controller.setAnimationState(walkingAnimationState(for: motion.velocity))
    }
  }

  private func walkingMotion(forPetID petID: String, frame: NSRect?, now: Date) -> WalkingMotion {
    if let motion = walkingMotionsByPetID[petID] {
      return motion
    }

    let frame = frame ?? NSRect(origin: .zero, size: PetWindowController.windowSize(scale: 1))
    let motion = randomWalkingMotion(
      now: now,
      frame: frame,
      screenFrame: screenFrame(containing: frame)
    )
    walkingMotionsByPetID[petID] = motion
    return motion
  }

  private func randomWalkingMotion(
    now: Date,
    frame: NSRect,
    screenFrame: NSRect
  ) -> WalkingMotion {
    let targetOrigin = randomTargetOrigin(for: frame, in: screenFrame)
    let speed = CGFloat.random(in: 38...62)
    let retargetDelay = TimeInterval.random(in: 6.0...14.0)

    return WalkingMotion(
      velocity: velocity(from: frame.origin, to: targetOrigin, speed: speed),
      targetOrigin: targetOrigin,
      speed: speed,
      retargetAt: now.addingTimeInterval(retargetDelay)
    )
  }

  private func randomTargetOrigin(for frame: NSRect, in screenFrame: NSRect) -> NSPoint {
    let padding: CGFloat = 24
    let minX = screenFrame.minX + padding
    let maxX = max(minX, screenFrame.maxX - frame.width - padding)
    let minY = screenFrame.minY + padding
    let maxY = max(minY, screenFrame.maxY - frame.height - padding)

    return NSPoint(
      x: CGFloat.random(in: minX...maxX),
      y: CGFloat.random(in: minY...maxY)
    )
  }

  private func velocity(from origin: NSPoint, to target: NSPoint, speed: CGFloat) -> CGVector {
    let deltaX = target.x - origin.x
    let deltaY = target.y - origin.y
    let distance = max(1, hypot(deltaX, deltaY))

    return CGVector(
      dx: deltaX / distance * speed,
      dy: deltaY / distance * speed
    )
  }

  private func walkingMovement(
    frame: NSRect,
    velocity: CGVector,
    elapsed: TimeInterval,
    screenFrame: NSRect
  ) -> WalkingMovement {
    let elapsed = CGFloat(elapsed)
    let minOriginX = screenFrame.minX
    let maxOriginX = max(minOriginX, screenFrame.maxX - frame.width)
    let minOriginY = screenFrame.minY
    let maxOriginY = max(minOriginY, screenFrame.maxY - frame.height)
    var nextOrigin = NSPoint(
      x: frame.origin.x + velocity.dx * elapsed,
      y: frame.origin.y + velocity.dy * elapsed
    )
    var nextVelocity = velocity
    var bouncedHorizontally = false
    var bouncedVertically = false

    if nextOrigin.x <= minOriginX {
      nextOrigin.x = minOriginX
      nextVelocity.dx = abs(nextVelocity.dx)
      bouncedHorizontally = true
    } else if nextOrigin.x >= maxOriginX {
      nextOrigin.x = maxOriginX
      nextVelocity.dx = -abs(nextVelocity.dx)
      bouncedHorizontally = true
    }

    if nextOrigin.y <= minOriginY {
      nextOrigin.y = minOriginY
      nextVelocity.dy = abs(nextVelocity.dy)
      bouncedVertically = true
    } else if nextOrigin.y >= maxOriginY {
      nextOrigin.y = maxOriginY
      nextVelocity.dy = -abs(nextVelocity.dy)
      bouncedVertically = true
    }

    return WalkingMovement(
      origin: nextOrigin,
      velocity: nextVelocity,
      bouncedHorizontally: bouncedHorizontally,
      bouncedVertically: bouncedVertically
    )
  }

  private func walkingAnimationState(for velocity: CGVector) -> AnimationState {
    velocity.dx < 0 ? .runningLeft : .runningRight
  }

  private func screenFrame(containing frame: NSRect) -> NSRect {
    let matchingScreen = NSScreen.screens.first { screen in
      screen.visibleFrame.intersects(frame)
    }

    return matchingScreen?.visibleFrame
      ?? NSScreen.main?.visibleFrame
      ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
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

private struct WalkingMotion {
  var velocity: CGVector
  var targetOrigin: NSPoint
  var speed: CGFloat
  var retargetAt: Date
}

private struct WalkingMovement {
  let origin: NSPoint
  let velocity: CGVector
  let bouncedHorizontally: Bool
  let bouncedVertically: Bool

  var didBounce: Bool {
    bouncedHorizontally || bouncedVertically
  }
}

extension NSPoint {
  fileprivate func distance(to point: NSPoint) -> CGFloat {
    hypot(point.x - x, point.y - y)
  }
}
