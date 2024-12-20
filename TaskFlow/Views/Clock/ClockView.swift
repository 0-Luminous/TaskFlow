import SwiftUI
import Foundation

struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var showingStatistics = false
    @State private var currentDate = Date()
    @State private var showingTodayTasks = false
    @State private var draggedCategory: TaskCategoryModel?  // Изменено здесь
    @State private var showingCategoryEditor = false
    @State private var selectedCategory: TaskCategoryModel?  // Изменено здесь
    
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
                    // Темное внешн е кольцо
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                    
                    // Маркеры часов
                    ForEach(0..<24) { hour in
                        MainClockMarker(hour: hour)
                    }
                    
                    // Существующий циферблат
                    MainClockFaceView(currentDate: currentDate, tasks: viewModel.tasks, viewModel: viewModel, draggedCategory: $draggedCategory, clockFaceColor: currentClockFaceColor)
                }
                Spacer()
                CategoryDockBar(viewModel: viewModel, 
                              showingAddTask: $showingAddTask, 
                              draggedCategory: $draggedCategory, 
                              showingCategoryEditor: $showingCategoryEditor,
                              selectedCategory: $selectedCategory)
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
                        Button(action: { showingCalendar = true }) {
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
            .sheet(isPresented: $showingCalendar) {
                CalendarView(viewModel: viewModel)
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
        return Color(hex: hexColor) ?? .white
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
    @Binding var draggedCategory: TaskCategoryModel?  // Изменено здесь
    @Binding var showingCategoryEditor: Bool
    @State private var isEditMode = false
    @Binding var selectedCategory: TaskCategoryModel?  // Изменено здесь
    @State private var currentPage = 0
    @State private var lastNonEditPage = 0
    
    let categoriesPerPage = 4
    let categoryWidth: CGFloat = 80
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 5) {
            TabView(selection: $currentPage) {
                ForEach(0..<numberOfPages, id: \.self) { page in
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: categoryWidth))], spacing: 10) {
                        ForEach(categoriesForPage(page)) { category in
                            CategoryButton(category: category, isSelected: selectedCategory == category)
                                .frame(width: categoryWidth, height: 80)
                                .onTapGesture {
                                    selectedCategory = category
                                }
                                .onDrag {
                                    self.draggedCategory = category
                                    return NSItemProvider(object: category.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: DropViewDelegate(item: category, items: $viewModel.categories, draggedItem: $draggedCategory))
                        }
                        
                        if isEditMode && shouldShowAddButton(on: page) {
                            Button(action: {
                                showingCategoryEditor = true
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                    Text("Добавить")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .frame(width: categoryWidth, height: 80)
                            }
                        }
                    }
                    .tag(page)
                }
            }
            .frame(height: 100)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(backgroundColorForTheme)
        .cornerRadius(20)
        .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation {
                        if !isEditMode {
                            lastNonEditPage = currentPage
                        }
                        isEditMode.toggle()
                        if isEditMode {
                            currentPage = pageWithAddButton
                        } else {
                            currentPage = min(lastNonEditPage, numberOfPages - 1)
                        }
                    }
                }
        )
        
        if numberOfPages > 1 {
            HStack {
                ForEach(0..<numberOfPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 5)
            .padding(.bottom, 10)
        }
    }
    
    private var backgroundColorForTheme: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9)
    }
    
    private var shadowColorForTheme: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    private var numberOfPages: Int {
        let categoriesCount = viewModel.categories.count
        if isEditMode {
            return max((categoriesCount + categoriesPerPage) / categoriesPerPage, 2)
        } else {
            return max((categoriesCount + categoriesPerPage - 1) / categoriesPerPage, 1)
        }
    }
    
    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {  // Изменено здесь
        let startIndex = page * categoriesPerPage
        let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
        return Array(viewModel.categories[startIndex..<endIndex])
    }
    
    private var pageWithAddButton: Int {
        let fullPages = viewModel.categories.count / categoriesPerPage
        return fullPages
    }
    
    private func shouldShowAddButton(on page: Int) -> Bool {
        return page == pageWithAddButton
    }
}

struct CategoryButton: View {
    let category: TaskCategoryModel  // Изменено здесь
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(category.color)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 3)
            )
            
            Text(category.rawValue)
                .font(.caption2)
                .foregroundColor(category.color)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(height: 80)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct DropViewDelegate: DropDelegate {
    let item: TaskCategoryModel  // Изменено здесь
    @Binding var items: [TaskCategoryModel]  // Изменено здесь
    @Binding var draggedItem: TaskCategoryModel?  // Изменено здесь

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else { return }
        if draggedItem != item {
            let from = items.firstIndex(of: draggedItem)!
            let to = items.firstIndex(of: item)!
            withAnimation(.default) {
                self.items.move(fromOffsets: IndexSet(integer: from),
                              toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// Переименованные компоненты для основного представления
struct MainClockMarker: View {
    let hour: Int
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.primary)
                .frame(width: hour % 3 == 0 ? 3 : 1, height: hour % 3 == 0 ? 15 : 10)
        }
        .offset(y: -UIScreen.main.bounds.width * 0.38)
        .rotationEffect(Angle.degrees(Double(hour) / 24 * 360))
    }
}

struct MainClockFaceView: View {
    let currentDate: Date
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var draggedCategory: TaskCategoryModel?
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    @State private var dropLocation: CGPoint?
    let clockFaceColor: Color
    
    private func timeForLocation(_ location: CGPoint) -> Date {
        let center = CGPoint(x: UIScreen.main.bounds.width * 0.35, y: UIScreen.main.bounds.width * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        
        // Рассчитываем угол в радианах
        var angle = atan2(vector.dy, vector.dx)
        
        // Конвертируем угол в градусы и корректируем для нашей системы координат
        // где 0 часов - влево (90 градусов)
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 + 360).truncatingRemainder(dividingBy: 360)
        
        // Конвертируем градусы в часы (360° / 24 = 15° на час)
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        
        return Calendar.current.date(from: components) ?? currentDate
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 2)
            
            MainTaskArcsView(tasks: tasks, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            
            MainClockMarksView()
            
            MainClockHandView(currentDate: currentDate)
            
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
            
            let newTask = Task(
                id: UUID(),
                title: "Новая задача",
                startTime: time,
                duration: 3600,
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
                TaskEditorView(viewModel: viewModel, task: task, isPresented: $showingTaskDetail)
            }
        }
    }
}

struct MainTaskArcsView: View {
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(tasks) { task in
                MainClockTaskArc(task: task, geometry: geometry, viewModel: viewModel, selectedTask: $selectedTask, showingTaskDetail: $showingTaskDetail)
            }
        }
    }
}

struct MainClockTaskArc: View {
    let task: Task
    let geometry: GeometryProxy
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedTask: Task?
    @Binding var showingTaskDetail: Bool
    
    private func calculateAngles() -> (start: Angle, end: Angle) {
        let calendar = Calendar.current
        
        // Получаем компоненты времени
        let startHour = CGFloat(calendar.component(.hour, from: task.startTime))
        let startMinute = CGFloat(calendar.component(.minute, from: task.startTime))
        let endTime = task.startTime.addingTimeInterval(task.duration)
        var endHour = CGFloat(calendar.component(.hour, from: endTime))
        let endMinute = CGFloat(calendar.component(.minute, from: endTime))
        
        // Рассчитываем углы в минутах (24 часа = 1440 минут)
        var startMinutes = startHour * 60 + startMinute
        var endMinutes = endHour * 60 + endMinute
        
        // Если конечное время меньше начального, добавляем 24 часа
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }
        
        // Конвертируем минуты в углы
        // Начинаем с 90 градусов (0 часов - влево)
        let startAngle = Angle(degrees: 90 + Double(startMinutes) / 4)
        let endAngle = Angle(degrees: 90 + Double(endMinutes) / 4)
        
        return (startAngle, endAngle)
    }
    
    private func calculateMidAngle(start: Angle, end: Angle) -> Angle {
        var midDegrees = (start.degrees + end.degrees) / 2
        
        // Корректируем середину для задач, переходящих через полночь
        if end.degrees < start.degrees {
            midDegrees = (start.degrees + (end.degrees + 360)) / 2
            if midDegrees >= 360 {
                midDegrees -= 360
            }
        }
        
        return Angle(degrees: midDegrees)
    }
    
    var body: some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2
        let (startAngle, endAngle) = calculateAngles()
        
        ZStack {
            Path { path in
                path.addArc(center: center, 
                           radius: radius + 10, 
                           startAngle: startAngle, 
                           endAngle: endAngle, 
                           clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
            
            let midAngle = calculateMidAngle(start: startAngle, end: endAngle)
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
}

struct MainClockHandView: View {
    let currentDate: Date
    @AppStorage("useManualTime") private var useManualTime = false
    
    private var displayDate: Date {
        if useManualTime,
           let manualTime = UserDefaults.standard.object(forKey: "manualTime") as? Date {
            return manualTime
        }
        return currentDate
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var timeComponents: (hour: Int, minute: Int) {
        (
            calendar.component(.hour, from: displayDate),
            calendar.component(.minute, from: displayDate)
        )
    }
    
    private var hourAngle: Double {
        let (hour, minute) = timeComponents
        let angle = 90 + (Double(hour) * 15 + Double(minute) * 0.25)
        return angle * .pi / 180
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let hourHandLength = radius * 1.22
                let angle = hourAngle
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle)),
                    y: center.y + hourHandLength * CGFloat(sin(angle))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(Color.blue, lineWidth: 3)
        }
    }
}

struct MainClockMarksView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24) { hour in
                MainClockMarkView(hour: hour, geometry: geometry, colorScheme: colorScheme)
            }
        }
    }
}

struct MainClockMarkView: View {
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

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView()
    }
}

struct iClockMarker: View {
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
