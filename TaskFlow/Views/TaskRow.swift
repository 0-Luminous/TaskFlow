import SwiftUI

struct TaskRow: View {
    let task: Task
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.category.iconName)
                .foregroundColor(task.category.color)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(task.category.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                    .strikethrough(isSelected)
                HStack {
                    Text(task.category.rawValue)
                        .font(.caption)
                        .padding(4)
                        .background(task.category.color.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(task.startTime, formatter: timeFormatter) - \(task.startTime.addingTimeInterval(task.duration), formatter: timeFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}
