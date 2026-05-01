import Foundation
import SwiftData

@Model
public final class TimerFolder {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var createdAt: Date
    public var sortOrder: Int
    
    @Relationship(deleteRule: .cascade, inverse: \TimerItem.folder)
    public var timers: [TimerItem]
    
    public init(name: String, colorHex: String = "#E8B4A5", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.timers = []
    }
}

@Model
public final class TimerItem {
    public var id: UUID
    public var name: String
    public var duration: TimeInterval
    public var colorHex: String
    public var soundName: String
    public var createdAt: Date
    public var sortOrder: Int
    public var isFavorite: Bool = false
    
    public var folder: TimerFolder?
    
    public init(name: String, duration: TimeInterval, colorHex: String = "#D4A373", soundName: String = "Gentle") {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.colorHex = colorHex
        self.soundName = soundName
        self.createdAt = Date()
        self.sortOrder = 0
        self.isFavorite = false
    }
}

enum TimerSound: String, CaseIterable {
    case gentle = "Gentle"
    case bell = "Bell"
    case chime = "Chime"
    case zen = "Zen"
    case soft = "Soft"
    case wave = "Wave"
    
    var systemSound: String {
        switch self {
        case .gentle: return "glass"
        case .bell: return "bell"
        case .chime: return "chime"
        case .zen: return "bloom"
        case .soft: return "morse"
        case .wave: return "sonar"
        }
    }
}
