import SwiftUI
import Combine
import Foundation

class ClockViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var selectedDate: Date = Date()
    @Published var categories: [TaskCategoryModel] = TaskCategoryModel.allCases
    @Published var selectedCategory: TaskCategoryModel = .work
    private var persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    let availableIcons = ["circle", "square", "triangle", "star", "heart", "person", "house", "car", "airplane", "book", "music.note", "flame", "bolt", "leaf", "moon", "sun.max"]

    init() {
        loadTasks()
        loadCategories()
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        $tasks
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveTasks()
            }
            .store(in: &cancellables)
        
        $categories
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveCategories()
            }
            .store(in: &cancellables)
    }
    func setSelectedDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    func addTask(_ task: Task) {
        tasks.append(task)
        tasks.sort { $0.startTime < $1.startTime }
        saveTasks()
    }

    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
            tasks.sort { $0.startTime < $1.startTime }
            saveTasks()
        }
    }

    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func addCategory(name: String, color: Color, icon: String) {
        let newCategory = TaskCategoryModel(rawValue: name, color: color, iconName: icon)
        categories.append(newCategory)
    }
    
    func removeCategories(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }

    private func saveTasks() {
        // Реализуйте сохранение задач (например, в UserDefaults или Core Data)
        print("Сохранение задач: \(tasks)") // Добавьте эту строку для отладки
    }

    private func loadTasks() {
        persistence.loadTasks { [weak self] result in
            switch result {
            case .success(let loadedTasks):
                DispatchQueue.main.async {
                    self?.tasks = loadedTasks
                }
            case .failure(let error):
                print("Failed to load tasks: \(error)")
            }
        }
    }
    
    private func saveCategories() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "savedCategories")
        }
    }
    
    private func loadCategories() {
        if let savedCategories = UserDefaults.standard.data(forKey: "savedCategories") {
            let decoder = JSONDecoder()
            if let loadedCategories = try? decoder.decode([TaskCategoryModel].self, from: savedCategories) {
                categories = loadedCategories
            }
        }
    }

    func tasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            calendar.isDate(task.startTime, inSameDayAs: date)
        }
    }

    func tasksByCategory() -> [TaskCategoryModel: [Task]] {
        Dictionary(grouping: tasks, by: { $0.category })
    }

    func updateCategory(_ category: TaskCategoryModel, newName: String, newColor: Color, newIcon: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = TaskCategoryModel(id: category.id, rawValue: newName, color: newColor, iconName: newIcon)
            
            // Обновляем задачи, связанные с этой категорией
            for i in 0..<tasks.count {
                if tasks[i].category.id == category.id {
                    tasks[i].category = categories[index]
                }
            }
        }
    }

    func exportTasksToCSV() -> String {
        var csvString = "Название,Категория,Начало,Продолжительность\n"
        
        for task in tasks {
            let taskRow = "\(task.title),\(task.category.rawValue),\(dateFormatter.string(from: task.startTime)),\(task.duration)\n"
            csvString.append(taskRow)
        }
        
        return csvString
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func addRepeatingTask(_ task: Task, repeatPattern: RepeatPattern) {
        let calendar = Calendar.current
        var currentDate = task.startTime

        for _ in 0..<repeatPattern.count {
            let newTask = Task(
                id: UUID(),
                title: task.title,
                startTime: currentDate,
                duration: task.duration,
                color: task.color,
                icon: task.icon,
                category: task.category
            )
            tasks.append(newTask)

            switch repeatPattern.type {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            }
        }
    }
}
