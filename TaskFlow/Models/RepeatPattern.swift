import Foundation

public enum RepeatPatternType {
    case daily, weekly, monthly
}

public struct RepeatPattern {
    public var type: RepeatPatternType
    public var count: Int
    
    public init(type: RepeatPatternType, count: Int) {
        self.type = type
        self.count = count
    }
}
