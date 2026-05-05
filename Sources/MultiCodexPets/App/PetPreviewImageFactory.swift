import AppKit
import MultiCodexPetsCore

enum PetPreviewImageFactory {
  static func image(for pet: PetPackage) -> NSImage? {
    let sourceImage: NSImage?
    if let spritesheetData = pet.spritesheetData {
      sourceImage = NSImage(data: spritesheetData)
    } else {
      sourceImage = NSImage(contentsOf: pet.spritesheetURL)
    }

    guard let sourceImage else { return nil }

    let previewSize = NSSize(width: 24, height: 26)
    let preview = NSImage(size: previewSize)
    preview.lockFocus()
    defer { preview.unlockFocus() }

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: previewSize).fill()
    NSGraphicsContext.current?.imageInterpolation = .none

    sourceImage.draw(
      in: NSRect(origin: .zero, size: previewSize),
      from: NSRect(
        x: 0,
        y: CGFloat(PetAtlas.height - PetAtlas.cellHeight),
        width: CGFloat(PetAtlas.cellWidth),
        height: CGFloat(PetAtlas.cellHeight)
      ),
      operation: .sourceOver,
      fraction: 1,
      respectFlipped: false,
      hints: nil
    )

    preview.isTemplate = false
    return preview
  }
}
