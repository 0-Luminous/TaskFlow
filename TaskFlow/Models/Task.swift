import Foundation
import SwiftUI

struct Task: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var title: String
    var startTime: Date
    var duration: TimeInterval
    var color: Color
    var icon: String
    var category: TaskCategoryModel
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, startTime: Date, duration: TimeInterval, color: Color, icon: String, category: TaskCategoryModel, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.color = color
        self.icon = icon
        self.category = category
        self.isCompleted = isCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id, title, startTime, duration, color, icon, category, isCompleted
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(color.toHex(), forKey: .color)
        try container.encode(icon, forKey: .icon)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(isCompleted, forKey: .isCompleted)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startTime = try container.decode(Date.self, forKey: .startTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        let colorHex = try container.decode(String.self, forKey: .color)
        color = Color(hex: colorHex) ?? .gray
        icon = try container.decode(String.self, forKey: .icon)
        let categoryRawValue = try container.decode(String.self, forKey: .category)
        category = TaskCategoryModel.allCases.first { $0.rawValue == categoryRawValue } ?? .work
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}
