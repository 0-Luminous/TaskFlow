import Foundation
import SwiftUI

struct Task: Identifiable, Equatable {
    let id: UUID
    var title: String
    var startTime: Date
    var duration: TimeInterval
    var color: Color
    var icon: String
    var category: TaskCategory

    init(id: UUID = UUID(), title: String, startTime: Date, duration: TimeInterval, color: Color, icon: String, category: TaskCategory) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.color = color
        self.icon = icon
        self.category = category
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.startTime == rhs.startTime &&
               lhs.duration == rhs.duration &&
               lhs.color == rhs.color &&
               lhs.icon == rhs.icon &&
               lhs.category == rhs.category
    }
}

struct TaskCategory: Hashable, Identifiable, CaseIterable {
    let id: UUID
    let rawValue: String
    let color: Color
    let iconName: String
    
    init(id: UUID = UUID(), rawValue: String, color: Color, iconName: String) {
        self.id = id
        self.rawValue = rawValue
        self.color = color
        self.iconName = iconName
    }
    
    static let food = TaskCategory(rawValue: "Еда", color: .green, iconName: "fork.knife")
    static let sport = TaskCategory(rawValue: "Спорт", color: .red, iconName: "figure.walk")
    static let sleep = TaskCategory(rawValue: "Сон", color: .blue, iconName: "bed.double")
    static let work = TaskCategory(rawValue: "Работа", color: .orange, iconName: "laptopcomputer")
    
    static var allCases: [TaskCategory] {
        [.food, .sport, .sleep, .work]
    }
}

// Добавьте это расширение для поддержки Codable
extension TaskCategory: Codable {
    enum CodingKeys: String, CodingKey {
        case id, rawValue, color, iconName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rawValue, forKey: .rawValue)
        try container.encode(color.toHex(), forKey: .color)
        try container.encode(iconName, forKey: .iconName)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        rawValue = try container.decode(String.self, forKey: .rawValue)
        let colorHex = try container.decode(String.self, forKey: .color)
        color = Color(hex: colorHex)
        iconName = try container.decode(String.self, forKey: .iconName)
    }
}
