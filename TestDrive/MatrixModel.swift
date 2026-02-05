import SwiftUI

struct MatrixWordDrop: Identifiable {
  let id: UUID
  let word: String
  let column: Int
  let xOffset: CGFloat
  let speed: CGFloat
  let phase: CGFloat
  let fontSize: CGFloat
  let opacity: CGFloat
}

struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: Int) {
    var value = UInt64(bitPattern: Int64(seed))
    if value == 0 { value = 0x4d595df4d0f33173 }
    self.state = value
  }

  mutating func next() -> UInt64 {
    state &+= 0x9e3779b97f4a7c15
    var z = state
    z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
    z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
    return z ^ (z >> 31)
  }
}

enum MatrixModel {
  static let defaultWords: [String] = [
    "Swift", "SwiftUI", "UIKit", "Xcode", "Combine", "Concurrency",
    "Actor", "Task", "Async", "Await", "MainActor", "Sendable",
    "AppStore", "TestFlight", "AppIcon", "AssetCatalog", "InfoPlist",
    "BundleID", "Keychain", "Token", "OAuth", "JWT", "Signing",
    "Provisioning", "Entitlement", "Certificate", "Simulator",
    "DeviceID", "Archive", "Profile", "Sandbox", "Push", "APNS",
    "WidgetKit", "CoreData", "CoreML", "Metal", "ARKit", "SwiftData",
    "URLSession", "Codable", "XCTest", "ViewModel", "Navigation",
    "SceneDelegate", "AppDelegate", "Preview", "AsyncStream",
    "Diffable", "Snapshot", "Bundle", "XCConfig", "Build", "Scheme"
  ]

  static func makeDrops(seed: Int, wordList: [String]) -> [MatrixWordDrop] {
    var rng = SeededGenerator(seed: seed)
    let columnCount = 20
    let dropCount = 200
    let fontSizes: [CGFloat] = [12, 14, 16, 18, 20]

    return (0..<dropCount).map { _ in
      let word = wordList[Int.random(in: 0..<wordList.count, using: &rng)]
      let column = Int.random(in: 0..<columnCount, using: &rng)
      let xOffset = CGFloat.random(in: -6...6, using: &rng)
      let speed = CGFloat.random(in: 24...120, using: &rng)
      let phase = CGFloat.random(in: 0...1200, using: &rng)
      let fontSize = fontSizes[Int.random(in: 0..<fontSizes.count, using: &rng)]
      let opacity = CGFloat.random(in: 0.35...0.9, using: &rng)
      return MatrixWordDrop(
        id: UUID(),
        word: word,
        column: column,
        xOffset: xOffset,
        speed: speed,
        phase: phase,
        fontSize: fontSize,
        opacity: opacity
      )
    }
  }
}
