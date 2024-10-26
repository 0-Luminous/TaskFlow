import SwiftUI

struct TaskCategoryModel: Hashable, Identifiable, Codable {
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
        color = Color(hex: colorHex) ?? .gray
        iconName = try container.decode(String.self, forKey: .iconName)
    }
    
    static let food = TaskCategoryModel(rawValue: "Еда", color: .green, iconName: "fork.knife")
    static let sport = TaskCategoryModel(rawValue: "Спорт", color: .red, iconName: "figure.walk")
    static let sleep = TaskCategoryModel(rawValue: "Сон", color: .blue, iconName: "bed.double")
    static let work = TaskCategoryModel(rawValue: "Работа", color: .orange, iconName: "laptopcomputer")
    
    static var allCases: [TaskCategoryModel] {
        [.food, .sport, .sleep, .work]
    }
}
