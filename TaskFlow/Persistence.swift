//
//  Persistence.swift
//  TaskFlow
//
//  Created by Yan on 13/10/24.
//

import CoreData
import SwiftUI // Добавлен импорт SwiftUI для использования Color

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newTask = TaskEntity(context: viewContext)
            newTask.id = UUID()
            newTask.title = "Пример задачи"
            newTask.startTime = Date()
            newTask.duration = 3600
            newTask.color = TaskCategory.work.color.toHex() // Изменено на TaskCategory
            newTask.icon = "circle"
            newTask.category = TaskCategory.work.rawValue // Изменено на TaskCategory
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskFlow")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Методы сохранения и загрузки задач
    func saveTasks(_ tasks: [Task]) {
        let context = container.viewContext
        // Удаляем существующие задачи перед сохранением новых
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TaskEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Не удалось удалить существующие задачи: \(error)")
        }

        for task in tasks {
            let newTaskEntity = TaskEntity(context: context)
            newTaskEntity.id = task.id
            newTaskEntity.title = task.title
            newTaskEntity.startTime = task.startTime
            newTaskEntity.duration = task.duration
            newTaskEntity.color = task.color.toHex()
            newTaskEntity.icon = task.icon
            newTaskEntity.category = task.category.rawValue // Изменено на TaskCategory
        }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    func loadTasks() -> [Task] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        do {
            let taskEntities = try context.fetch(fetchRequest)
            return taskEntities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let colorHex = entity.color,
                      let categoryRaw = entity.category,
                      let category = TaskCategory.allCases.first(where: { $0.rawValue == categoryRaw }) else {
                    return nil
                }
                return Task(
                    id: id,
                    title: title,
                    startTime: entity.startTime ?? Date(),
                    duration: entity.duration,
                    color: Color(hex: colorHex),
                    icon: entity.icon ?? "circle",
                    category: category
                )
            }
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
}
