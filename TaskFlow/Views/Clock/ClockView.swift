import SwiftUI

struct ClockView: View {
    @StateObject private var viewModel = ClockViewModel()
    @State private var showingAddTask = false
    @State private var showingSettings = false
    @State private var showingCategoryEditor = false
    @State private var currentDate = Date()
    @State private var draggedCategory: TaskCategory?
    @State private var clockOffset: CGFloat = 0
    
    @AppStorage("backgroundColor") private var backgroundColor = Color.white.toHex()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                HStack(alignment: .center, spacing: 20) {
                    clockFace
                    categoryButtons
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
                    Button(action: { 
                        viewModel.selectedCategory = .work
                        showingAddTask = true 
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel, isPresented: $showingAddTask)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .background(Color(hex: backgroundColor))
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var clockFace: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 2)
            
            ForEach(viewModel.tasks) { task in
                ClockTaskArc(task: task)
            }
            
            ClockFaceView()
            
            ClockHandView(currentDate: currentDate)
            
            Circle()
                .fill(Color.black.opacity(0.85))
                .frame(width: 10, height: 10)
            
            clockCenterText
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .onReceive(timer) { _ in
            currentDate = Date()
        }
        .offset(x: clockOffset)
    }

    private var clockCenterText: some View {
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

    private var categoryButtons: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.categories, id: \.self) { category in
                CategoryButton(category: category, action: {
                    viewModel.selectedCategory = category
                    showingAddTask = true
                })
                .onDrag {
                    self.draggedCategory = category
                    return NSItemProvider(object: category.rawValue as NSString)
                }
            }
            addCategoryButton
        }
        .padding(.trailing)
    }

    private var addCategoryButton: some View {
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

struct ClockTaskArc: View {
    let task: Task
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
                let startAngle = self.angleForTime(task.startTime)
                let endTime = task.startTime.addingTimeInterval(task.duration)
                let endAngle = self.angleForTime(endTime)
                
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
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

struct CategoryButton: View {
    let category: TaskCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: category.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(15)
                .frame(width: 50, height: 50)
                .background(category.color.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}

struct ClockDropDelegate: DropDelegate {
    let viewModel: ClockViewModel
    
    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.text]).first else { return false }
        
        item.loadObject(ofClass: NSString.self) { (reading, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let categoryRawValue = reading as? String,
                  let category = viewModel.categories.first(where: { $0.rawValue == categoryRawValue }) else { return }
            
            DispatchQueue.main.async {
                let newTask = Task(title: "Новая задача", startTime: Date(), duration: 3600, color: category.color, icon: category.iconName, category: category)
                self.viewModel.addTask(newTask)
            }
        }
        return true
    }
}

struct ClockFaceView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<24) { hour in
                    HourMark(hour: hour, geometry: geometry, colorScheme: colorScheme)
                    HourLabel(hour: hour, geometry: geometry, colorScheme: colorScheme)
                }
            }
        }
    }
}

struct HourMark: View {
    let hour: Int
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    
    var body: some View {
        Path { path in
            let angle = CGFloat(hour) * .pi / 12
            let length: CGFloat = hour % 3 == 0 ? 15 : 10
            let start = CGPoint(
                x: geometry.size.width / 2 + (geometry.size.width / 2 - length) * cos(angle),
                y: geometry.size.height / 2 + (geometry.size.width / 2 - length) * sin(angle)
            )
            let end = CGPoint(
                x: geometry.size.width / 2 + (geometry.size.width / 2) * cos(angle),
                y: geometry.size.height / 2 + (geometry.size.width / 2) * sin(angle)
            )
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: hour % 3 == 0 ? 2 : 1)
    }
}

struct HourLabel: View {
    let hour: Int
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    
    var body: some View {
        Text("\(hour)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .position(
                x: geometry.size.width / 2 + (geometry.size.width / 2 - 30) * cos(CGFloat(hour) * .pi / 12),
                y: geometry.size.height / 2 + (geometry.size.width / 2 - 30) * sin(CGFloat(hour) * .pi / 12)
            )
    }
}

struct ClockTaskView: View {
    let task: Task
    @ObservedObject var viewModel: ClockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 10
                let startAngle = angleForTime(task.startTime)
                let endAngle = angleForTime(task.startTime.addingTimeInterval(task.duration))
                
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(task.category.color, lineWidth: 20)
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
        return Angle(degrees: Double(totalMinutes) / 4 - 90)
    }
}

#Preview {
    ClockView()
}
