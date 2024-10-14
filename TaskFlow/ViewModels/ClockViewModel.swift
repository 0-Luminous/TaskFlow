import SwiftUI
import Combine

class ClockViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var categories: [TaskCategory] = TaskCategory.allCases
    @Published var selectedCategory: TaskCategory = .work
    private var persistence = PersistenceController.shared
    
    let availableIcons = ["circle", "square", "triangle", "star", "heart", "person", "house", "car", "airplane", "book", "music.note", "flame", "bolt", "leaf", "moon", "sun.max"]

    init() {
        loadTasks()
        loadCategories()
    }

    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }

    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
            saveTasks()
        }
    }

    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func addCategory(name: String, color: Color, icon: String) {
        let newCategory = TaskCategory(rawValue: name, color: color, iconName: icon)
        categories.append(newCategory)
        saveCategories()
    }
    
    func removeCategories(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        saveCategories()
    }

    private func saveTasks() {
        persistence.saveTasks(tasks)
    }

    private func loadTasks() {
        tasks = persistence.loadTasks()
    }
    
    private func saveCategories() {
        // Implement saving categories to UserDefaults or other storage
    }
    
    private func loadCategories() {
        // Implement loading categories from UserDefaults or other storage
    }
}
