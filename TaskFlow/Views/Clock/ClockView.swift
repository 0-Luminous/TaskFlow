import SwiftUI
import Foundation

struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingTaskFlow = false
    @State private var showingStatistics = false
    @State private var currentDate = Date()
    @State private var showingTodayTasks = false
    @State private var draggedCategory: TaskCategory?
    @State private var showingCategoryEditor = false
    
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor = Color.black.toHex()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @Environment(\.colorScheme) var colorScheme
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                ZStack {
                    // Темное внешнее кольцо
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                    
                    // Маркеры часов
                    ForEach(0..<24) { hour in
                        ClockMarker(hour: hour)
                    }
                    
                    // Существующий циферблат
                    ClockFaceView(currentDate: currentDate, tasks: viewModel.tasks, viewModel: viewModel, draggedCategory: $draggedCategory, clockFaceColor: currentClockFaceColor)
                }
                Spacer()
                CategoryDockBar(viewModel: viewModel, showingAddTask: $showingAddTask, draggedCategory: $draggedCategory, showingCategoryEditor: $showingCategoryEditor)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(formattedDate)
                            .font(.headline)
                        Text(formattedWeekday)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                        }
                        Button(action: { showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingTaskFlow = true }) {
                            Image(systemName: "calendar")
                        }
                        Button(action: { showingTodayTasks = true }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskEditorView(viewModel: viewModel, isPresented: $showingAddTask)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTaskFlow) {
                TaskFlowView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingTodayTasks) {
                TodayTasksView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingCategoryEditor) {
                CategoryEditorView(viewModel: viewModel, isPresented: $showingCategoryEditor, clockOffset: .constant(0))
            }
        }
        .background(currentClockFaceColor)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private var currentClockFaceColor: Color {
        let hexColor = colorScheme == .dark ? darkModeClockFaceColor : lightModeClockFaceColor
        return Color(hex: hexColor) // Удалим оператор ??
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: currentDate)
    }
    
    private var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: currentDate).capitalized
    }
}

struct CategoryDockBar: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var showingAddTask: Bool
    @Binding var draggedCategory: TaskCategory?
    @Binding var showingCategoryEditor: Bool
    @State private var isEditMode = false
    @State private var editingCategory: TaskCategory?
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.categories, id: \.self) { category in
                CategoryButton(category: category)
                    .onDrag {
                        self.draggedCategory = category
                        return NSItemProvider(object: category.rawValue as NSString)
                    }
            }
            
            if isEditMode {
                Button(action: {
                    showingCategoryEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation {
                        isEditMode.toggle()
                    }
                }
        )
    }
}

struct CategoryButton: View {
    let category: TaskCategory
    @State private var isDragging = false
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(category.color)
            }
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.spring(), value: isDragging)
            
            Text(category.rawValue)
                .font(.caption2)
                .foregroundColor(category.color)
        }
        .frame(width: 60, height: 70)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

struct ClockFaceView: View {
    let currentDate: Date
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var draggedCategory: TaskCategory?
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    @State private var dropLocation: CGPoint?
    let clockFaceColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            TaskArcsView(tasks: tasks, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            
            ClockMarksView()
            
            ClockHandView(currentDate: currentDate)
            
            if let location = dropLocation {
                Circle()
                    .fill(draggedCategory?.color ?? .clear)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.7)
        .padding()
        .animation(.spring(), value: tasks)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            guard let category = draggedCategory else { return false }
            
            let dropPoint = location
            self.dropLocation = dropPoint
            
            let time = timeForLocation(dropPoint)
            
            // Создаем новую задачу с учетом структуры Task
            let newTask = Task(
                id: UUID(),
                title: "Новая задача",
                startTime: time,
                duration: 3600, // 1 час по умолчанию
                color: category.color,
                icon: category.iconName,
                category: category,
                isCompleted: false
            )
            viewModel.addTask(newTask)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.dropLocation = nil
            }
            
            return true
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, viewModel: viewModel, isPresented: $showingTaskDetail)
            }
        }
    }
    
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(x: UIScreen.main.bounds.width * 0.35, y: UIScreen.main.bounds.width * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let normalizedAngle = (angle + .pi / 2).truncatingRemainder(dividingBy: .pi * 2)
        let hours = normalizedAngle / (.pi / 12)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = Int(hours)
        components.minute = Int((hours.truncatingRemainder(dividingBy: 1)) * 60)
        
        return Calendar.current.date(from: components) ?? currentDate
    }
}

struct TaskArcsView: View {
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(tasks) { task in
                ClockTaskArc(task: task, geometry: geometry, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            }
        }
    }
}

struct ClockTaskArc: View {
    let task: Task
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    var body: some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2
        let startAngle = angleForTime(task.startTime)
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let endAngle = angleForTime(endTime)
        
        ZStack {
            Path { path in
                path.addArc(center: center, radius: radius + 10, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
            
            // Добавляем иконку категории в середине дуги
            let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
            Image(systemName: task.category.iconName)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .background(
                    Circle()
                        .fill(task.category.color)
                        .frame(width: 20, height: 20)
                )
                .position(
                    x: center.x + (radius + 20) * cos(midAngle.radians),
                    y: center.y + (radius + 20) * sin(midAngle.radians)
                )
        }
        .onTapGesture {
            selectedTask = task
            showingTaskDetail = true
        }
    }
    
    private func angleForTime(_ time: Date) -> Angle {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: time))
        let minute = CGFloat(calendar.component(.minute, from: time))
        let totalMinutes = hour * 60 + minute
        return Angle(degrees: Double(totalMinutes) / 4 - 90)
    }
}

struct ClockMarksView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24) { hour in
                ClockMarkView(hour: hour, geometry: geometry, colorScheme: colorScheme)
            }
        }
    }
}

struct ClockMarkView: View {
    let hour: Int
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    
    var body: some View {
        Group {
            clockMarkLine
            clockMarkText
        }
    }
    
    private var clockMarkLine: some View {
        Path { path in
            let angle = CGFloat(hour) * .pi / 12
            let length: CGFloat = hour % 3 == 0 ? 15 : 10
            let start = startPoint(angle: angle, length: length)
            let end = endPoint(angle: angle)
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: hour % 3 == 0 ? 2 : 1)
    }
    
    private func startPoint(angle: CGFloat, length: CGFloat) -> CGPoint {
        CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2 - length) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2 - length) * sin(angle)
        )
    }
    
    private func endPoint(angle: CGFloat) -> CGPoint {
        CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2) * sin(angle)
        )
    }
    
    private var clockMarkText: some View {
        let angle = CGFloat(hour) * .pi / 12 + .pi / 2
        let radius = geometry.size.width / 2 - 30
        let xPosition = geometry.size.width / 2 + radius * cos(angle)
        let yPosition = geometry.size.height / 2 + radius * sin(angle)
        
        return Text("\(hour)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .position(x: xPosition, y: yPosition)
    }
}

struct ClockHandView: View {
    let currentDate: Date
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let hourHandLength = radius * 1.22
                // Уменьшаем длину стрелки
                let angle = angleForTime(currentDate)
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle.radians)),
                    y: center.y + hourHandLength * CGFloat(sin(angle.radians))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(colorScheme == .dark ? Color.red : Color.blue, lineWidth: 3)
        }
    }
    
    private func angleForTime(_ time: Date) -> Angle {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: time))
        let minute = CGFloat(calendar.component(.minute, from: time))
        let totalMinutes = hour * 60 + minute
        return Angle(degrees: Double(totalMinutes) / 2 - 90) // Изменяем формулу для правильного направления
    }
}

struct ClockCenterView: View {
    let currentDate: Date
    
    var body: some View {
        VStack {
            Text(currentDate, style: .date)
                .font(.system(size: 18, weight: .bold))
            Text(currentDate, style: .time)
                .font(.system(size: 24, weight: .bold))
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct TaskDetailView: View {
    let task: Task
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Детали задачи")) {
                    Text("Название: \(task.title)")
                    Text("Категория: \(task.category.rawValue)")
                    Text("Начало: \(task.startTime, formatter: dateFormatter)")
                    Text("Продолжительность: \(formattedDuration)")
                }
                
                Section {
                    Button("Редактировать") {
                        // Здесь мы можем открыть TaskEditorView для ректирования
                    }
                    Button("Удалить", role: .destructive) {
                        viewModel.removeTask(task)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Инфо")
            .navigationBarItems(trailing: Button("Закрыть") {
                isPresented = false
            })
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var formattedDuration: String {
        let hours = Int(task.duration) / 3600
        let minutes = (Int(task.duration) % 3600) / 60
        return "\(hours) ч \(minutes) мин"
    }
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView()
    }
}

struct ClockMarker: View {
    let hour: Int
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: hour % 3 == 0 ? 3 : 1, height: hour % 3 == 0 ? 15 : 10)
        }
        .offset(y: -UIScreen.main.bounds.width * 0.38)
        .rotationEffect(Angle.degrees(Double(hour) / 24 * 360))
    }
}
