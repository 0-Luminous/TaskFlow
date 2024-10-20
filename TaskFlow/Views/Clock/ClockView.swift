import SwiftUI
import Foundation

struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingCategoryEditor = false
    @State private var showingTaskFlow = false
    @State private var showingStatistics = false
    @State private var currentDate = Date()
    @State private var clockOffset: CGFloat = 0
    @State private var showingTodayTasks = false
    
    @AppStorage("backgroundColor") private var backgroundColor = Color.white.toHex()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                HStack(alignment: .center, spacing: 20) {
                    ClockFaceView(currentDate: currentDate, tasks: viewModel.tasks, clockOffset: $clockOffset, viewModel: viewModel)
                    CategoryButtonsView(viewModel: viewModel, showingAddTask: $showingAddTask, showingCategoryEditor: $showingCategoryEditor, clockOffset: $clockOffset)
                }
                
                if showingCategoryEditor {
                    CategoryEditorView(viewModel: viewModel, isPresented: $showingCategoryEditor, clockOffset: $clockOffset)
                        .transition(.move(edge: .trailing))
                }
            }
            .navigationTitle("Ежедневник")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { 
                            viewModel.selectedCategory = .work
                            showingAddTask = true 
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: { showingTaskFlow = true }) {
                            Image(systemName: "calendar")
                        }
                        
                        Button(action: { showingStatistics = true }) {
                            Image(systemName: "chart.bar")
                        }
                        
                        // Добавьте эту кнопку
                        Button(action: { showingTodayTasks = true }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel, isPresented: $showingAddTask)
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
        }
        .background(Color(hex: backgroundColor))
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
}

struct ClockFaceView: View {
    let currentDate: Date
    let tasks: [Task]
    @Binding var clockOffset: CGFloat
    @ObservedObject var viewModel: ClockViewModel
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 2)
            
            TaskArcsView(tasks: tasks, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            
            ClockMarksView()
            
            ClockHandView(currentDate: currentDate)
            
            ClockCenterView(currentDate: currentDate)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .offset(x: clockOffset)
        .animation(.spring(), value: tasks)
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task, viewModel: viewModel, isPresented: $showingTaskDetail)
            }
        }
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
        Path { path in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
            let startAngle = self.angleForTime(task.startTime)
            let endTime = task.startTime.addingTimeInterval(task.duration)
            let endAngle = self.angleForTime(endTime)
            
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        }
        .stroke(task.category.color, lineWidth: 20)
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
        return Angle(degrees: Double(totalMinutes) / 4 + 90)
    }
}

struct CategoryButtonsView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var showingAddTask: Bool
    @Binding var showingCategoryEditor: Bool
    @Binding var clockOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.categories, id: \.self) { category in
                CategoryButton(category: category, action: {
                    viewModel.selectedCategory = category
                    showingAddTask = true
                })
            }
            AddCategoryButton(showingCategoryEditor: $showingCategoryEditor, clockOffset: $clockOffset)
        }
        .padding(.trailing)
    }
}

struct AddCategoryButton: View {
    @Binding var showingCategoryEditor: Bool
    @Binding var clockOffset: CGFloat
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                clockOffset = -UIScreen.main.bounds.width
                showingCategoryEditor = true
            }
        }) {
            Image(systemName: "plus.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
        }
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
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
                let angle = angleForTime(currentDate)
                let endpoint = CGPoint(
                    x: center.x + radius * CGFloat(cos(angle.radians)),
                    y: center.y + radius * CGFloat(sin(angle.radians))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(colorScheme == .dark ? Color.red : Color.blue, lineWidth: 2)
        }
    }
    
    private func angleForTime(_ time: Date) -> Angle {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: time))
        let minute = CGFloat(calendar.component(.minute, from: time))
        let totalMinutes = hour * 60 + minute
        return Angle(degrees: Double(totalMinutes) / 4 + 90)
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
                        // Здесь мы можем открыть TaskEditorView для редактирования
                    }
                    Button("Удалить", role: .destructive) {
                        viewModel.removeTask(task)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Инфомация о задаче")
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

struct CategoryButton: View {
    let category: TaskCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                Text(category.rawValue)
                    .font(.caption)
            }
            .foregroundColor(category.color)
            .frame(width: 60, height: 60)
            .background(category.color.opacity(0.2))
            .cornerRadius(10)
        }
    }
}
