import Foundation
import MultiCodexPetsCore

final class AppSettings {
  private enum Key {
    static let visiblePetCount = "visiblePetCount"
    static let selectedPetIDs = "selectedPetIDs"
    static let animationState = "animationState"
    static let scale = "scale"
    static let walksAround = "walksAround"
  }

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var visiblePetCount: Int {
    get {
      let value = defaults.integer(forKey: Key.visiblePetCount)
      return value == 0 ? 2 : value
    }
    set {
      defaults.set(newValue, forKey: Key.visiblePetCount)
    }
  }

  var selectedPetIDs: [String]? {
    get {
      guard let ids = defaults.array(forKey: Key.selectedPetIDs) as? [String] else {
        return nil
      }

      return ids.uniqueNonEmptyValues
    }
    set {
      guard let newValue else {
        defaults.removeObject(forKey: Key.selectedPetIDs)
        return
      }

      defaults.set(newValue.uniqueNonEmptyValues, forKey: Key.selectedPetIDs)
    }
  }

  var animationState: AnimationState {
    get {
      guard let rawValue = defaults.string(forKey: Key.animationState),
        let state = AnimationState(rawValue: rawValue)
      else {
        return .idle
      }

      return state
    }
    set {
      defaults.set(newValue.rawValue, forKey: Key.animationState)
    }
  }

  var scale: Double {
    get {
      let value = defaults.double(forKey: Key.scale)
      return value == 0 ? 1 : value
    }
    set {
      defaults.set(newValue, forKey: Key.scale)
    }
  }

  var walksAround: Bool {
    get {
      defaults.bool(forKey: Key.walksAround)
    }
    set {
      defaults.set(newValue, forKey: Key.walksAround)
    }
  }
}

extension Array where Element == String {
  fileprivate var uniqueNonEmptyValues: [String] {
    var seen = Set<String>()
    return compactMap { value in
      guard let trimmed = value.trimmedNonEmpty, !seen.contains(trimmed) else {
        return nil
      }

      seen.insert(trimmed)
      return trimmed
    }
  }
}
