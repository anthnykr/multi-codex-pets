import AppKit
import MultiCodexPetsCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let settings = AppSettings()
  private let petLoader = PetPackageLoader()
  private lazy var defaultPetLoader = CodexDefaultPetLoader(
    codexAppURL: Self.resolveCodexAppURL()
  )
  private let petCoordinator = PetCoordinator()

  private var statusItem: NSStatusItem?
  private var petPackages: [PetPackage] = []
  private var previewImages: [String: NSImage] = [:]

  func applicationDidFinishLaunching(_ notification: Notification) {
    configureMenuBarItem()
    refreshPets()
    showConfiguredPets()
  }

  private func configureMenuBarItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = item.button {
      if let image = NSImage(
        systemSymbolName: "pawprint.fill", accessibilityDescription: "Multi Codex Pets")
      {
        image.isTemplate = true
        button.image = image
      } else {
        button.title = "Pets"
      }
      button.toolTip = "Multi Codex Pets"
    }

    statusItem = item
    rebuildMenu()
  }

  private func rebuildMenu() {
    let menu = NSMenu()

    let defaultPetCount = petPackages.filter { $0.source == .codexDefault }.count
    let customPetCount = petPackages.filter { $0.source == .custom }.count
    let selectedCount = selectedPetPackages.count
    let summary =
      petPackages.isEmpty
      ? "No valid pets found"
      : "\(petPackages.count) pet\(petPackages.count == 1 ? "" : "s")"
        + " (\(selectedCount) visible, \(defaultPetCount) Codex, \(customPetCount) custom)"
    let summaryItem = NSMenuItem(title: summary, action: nil, keyEquivalent: "")
    summaryItem.isEnabled = false
    menu.addItem(summaryItem)
    menu.addItem(.separator())

    let toggleTitle = petCoordinator.isShowingPets ? "Hide Pets" : "Show Pets"
    menu.addItem(actionItem(title: toggleTitle, action: #selector(togglePets)))

    let walkingItem = actionItem(title: "Walk Around", action: #selector(toggleWalkAround))
    walkingItem.state = settings.walksAround ? .on : .off
    menu.addItem(walkingItem)

    menu.addItem(actionItem(title: "Refresh Pets", action: #selector(refreshPetsAction)))

    let visiblePetsRoot = NSMenuItem(title: "Visible Pets", action: nil, keyEquivalent: "")
    visiblePetsRoot.submenu = visiblePetsMenu()
    menu.addItem(visiblePetsRoot)

    let stateMenu = NSMenu()
    for state in AnimationState.allCases {
      let item = actionItem(title: state.displayName, action: #selector(setAnimationState(_:)))
      item.representedObject = state.rawValue
      item.state = settings.animationState == state ? .on : .off
      stateMenu.addItem(item)
    }
    let stateRoot = NSMenuItem(title: "Animation", action: nil, keyEquivalent: "")
    stateRoot.submenu = stateMenu
    menu.addItem(stateRoot)

    let scaleMenu = NSMenu()
    for option in scaleOptions {
      let item = actionItem(title: option.title, action: #selector(setScale(_:)))
      item.representedObject = option.value
      item.state = abs(settings.scale - option.value) < 0.01 ? .on : .off
      scaleMenu.addItem(item)
    }
    let scaleRoot = NSMenuItem(title: "Scale", action: nil, keyEquivalent: "")
    scaleRoot.submenu = scaleMenu
    menu.addItem(scaleRoot)

    menu.addItem(.separator())
    menu.addItem(actionItem(title: "Open Custom Pet Folder", action: #selector(openPetFolder)))
    menu.addItem(.separator())
    menu.addItem(actionItem(title: "Quit", action: #selector(quit)))

    statusItem?.menu = menu
  }

  private func actionItem(title: String, action: Selector) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
    item.target = self
    return item
  }

  private func visiblePetsMenu() -> NSMenu {
    let menu = NSMenu()

    guard !petPackages.isEmpty else {
      let item = NSMenuItem(title: "No valid pets found", action: nil, keyEquivalent: "")
      item.isEnabled = false
      menu.addItem(item)
      return menu
    }

    menu.addItem(actionItem(title: "Select All", action: #selector(selectAllPets)))
    menu.addItem(actionItem(title: "Clear Selection", action: #selector(clearVisiblePets)))
    menu.addItem(.separator())

    addVisiblePetItems(
      titled: "Codex Defaults",
      packages: petPackages.filter { $0.source == .codexDefault },
      to: menu
    )
    addVisiblePetItems(
      titled: "Custom Pets",
      packages: petPackages.filter { $0.source == .custom },
      to: menu
    )

    return menu
  }

  private func addVisiblePetItems(
    titled title: String,
    packages: [PetPackage],
    to menu: NSMenu
  ) {
    guard !packages.isEmpty else { return }

    if menu.items.last?.isSeparatorItem == false {
      menu.addItem(.separator())
    }

    let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
    header.isEnabled = false
    menu.addItem(header)

    let selectedIDs = selectedPetIDs
    for package in packages {
      let item = actionItem(title: package.displayName, action: #selector(toggleVisiblePet(_:)))
      item.representedObject = package.id
      item.state = selectedIDs.contains(package.id) ? .on : .off
      item.image = previewImage(for: package)
      menu.addItem(item)
    }
  }

  private func previewImage(for package: PetPackage) -> NSImage? {
    if let cached = previewImages[package.id] {
      return cached
    }

    let image = PetPreviewImageFactory.image(for: package)
    previewImages[package.id] = image
    return image
  }

  private func showConfiguredPets() {
    guard !petPackages.isEmpty else {
      petCoordinator.hidePets()
      rebuildMenu()
      return
    }

    let packages = selectedPetPackages
    guard !packages.isEmpty else {
      petCoordinator.hidePets()
      rebuildMenu()
      return
    }

    petCoordinator.showPets(
      packages,
      state: settings.animationState,
      scale: settings.scale
    )
    petCoordinator.setWalksAround(
      settings.walksAround,
      baseState: settings.animationState
    )
    rebuildMenu()
  }

  private func refreshPets() {
    petPackages = defaultPetLoader.loadPackages() + petLoader.loadPackages()
    previewImages.removeAll()
    updateSelectedPetsAfterPackageRefresh()
    if petCoordinator.isShowingPets {
      showConfiguredPets()
    } else {
      rebuildMenu()
    }
  }

  @objc private func togglePets() {
    if petCoordinator.isShowingPets {
      petCoordinator.hidePets()
      rebuildMenu()
    } else {
      showConfiguredPets()
    }
  }

  @objc private func refreshPetsAction() {
    refreshPets()
  }

  @objc private func toggleWalkAround() {
    settings.walksAround.toggle()
    petCoordinator.setWalksAround(
      settings.walksAround,
      baseState: settings.animationState
    )
    rebuildMenu()
  }

  @objc private func toggleVisiblePet(_ sender: NSMenuItem) {
    guard let id = sender.representedObject as? String else { return }

    var ids = settings.selectedPetIDs ?? legacySelectedPetIDs()
    if ids.contains(id) {
      ids.removeAll { $0 == id }
    } else {
      ids.append(id)
    }
    settings.selectedPetIDs = ids

    showConfiguredPets()
  }

  @objc private func selectAllPets() {
    settings.selectedPetIDs = petPackages.map(\.id)
    showConfiguredPets()
  }

  @objc private func clearVisiblePets() {
    settings.selectedPetIDs = []
    showConfiguredPets()
  }

  @objc private func setAnimationState(_ sender: NSMenuItem) {
    guard let rawValue = sender.representedObject as? String,
      let state = AnimationState(rawValue: rawValue)
    else {
      return
    }

    settings.animationState = state
    petCoordinator.setAnimationState(state)
    rebuildMenu()
  }

  @objc private func setScale(_ sender: NSMenuItem) {
    guard let scale = sender.representedObject as? Double else { return }
    settings.scale = scale
    petCoordinator.setScale(scale)
    rebuildMenu()
  }

  @objc private func openPetFolder() {
    do {
      try petLoader.ensurePetsDirectoryExists()
      NSWorkspace.shared.open(petLoader.petsDirectory)
    } catch {
      NSSound.beep()
    }
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  private var scaleOptions: [(title: String, value: Double)] {
    [
      ("75%", 0.75),
      ("100%", 1.0),
      ("125%", 1.25),
      ("150%", 1.5),
    ]
  }

  private var selectedPetIDs: Set<String> {
    Set(settings.selectedPetIDs ?? legacySelectedPetIDs())
  }

  private var selectedPetPackages: [PetPackage] {
    let ids = selectedPetIDs
    return petPackages.filter { ids.contains($0.id) }
  }

  private func updateSelectedPetsAfterPackageRefresh() {
    let availableIDs = Set(petPackages.map(\.id))

    if let selectedIDs = settings.selectedPetIDs {
      settings.selectedPetIDs = selectedIDs.filter { availableIDs.contains($0) }
      return
    }

    guard !petPackages.isEmpty else { return }
    settings.selectedPetIDs = legacySelectedPetIDs()
  }

  private func legacySelectedPetIDs() -> [String] {
    guard !petPackages.isEmpty else { return [] }

    if settings.visiblePetCount == -1 {
      return petPackages.map(\.id)
    }

    let count = min(max(1, settings.visiblePetCount), petPackages.count)
    return Array(petPackages.prefix(count)).map(\.id)
  }

  private static func resolveCodexAppURL() -> URL {
    if let override = ProcessInfo.processInfo.environment["CODEX_APP_PATH"]?.trimmedNonEmpty {
      return URL(fileURLWithPath: override, isDirectory: true)
    }

    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex")
      ?? CodexDefaultPetLoader.defaultCodexAppURL()
  }
}
