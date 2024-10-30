//
//  SettingsView.swift
//  TaskFlow
//
//  Created by Yan on 13/10/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("sortOption") private var sortOption = SortOption.startTime.rawValue
    @AppStorage("useManualTime") private var useManualTime = false
    @State private var selectedTime = Date()
    @State private var showingTimeSavedAlert = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case startTime = "Началу"
        case title = "Заголовку"
        case category = "Категории"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        TabView {
            // Вкладка с основными настройками
            NavigationView {
                List {
                    Section(header: Text("Время")) {
                        Toggle("Установить время вручную", isOn: $useManualTime)
                        
                        if useManualTime {
                            DatePicker("Выбрать время",
                                     selection: $selectedTime,
                                     displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                            
                            Button(action: {
                                saveManualTime()
                                showingTimeSavedAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "clock.badge.checkmark")
                                    Text("Сохранить время")
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Section(header: Text("Уведомления")) {
                        Toggle("Включить уведомления", isOn: $notificationsEnabled)
                    }
                    
                    Section(header: Text("Сортировка задач")) {
                        Picker("Сортировать по", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section {
                        Button(action: resetSettings) {
                            Text("Сбросить настройки")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Настройки")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            dismiss()
                        }
                    }
                }
                .alert("Время сохранено", isPresented: $showingTimeSavedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Выбранное время успешно установлено")
                }
            }
            .tabItem {
                Label("Основные", systemImage: "gear")
            }
            
            // Вкладка для выбора цветов циферблата
            ColorSettingsView()
                .tabItem {
                    Label("Цвета", systemImage: "paintbrush")
                }
        }
        .onAppear {
            if let savedTime = UserDefaults.standard.object(forKey: "manualTime") as? Date {
                selectedTime = savedTime
            }
        }
    }
    
    private func saveManualTime() {
        UserDefaults.standard.set(selectedTime, forKey: "manualTime")
        UserDefaults.standard.synchronize()
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        sortOption = SortOption.startTime.rawValue
        useManualTime = false
        UserDefaults.standard.removeObject(forKey: "manualTime")
        UserDefaults.standard.synchronize()
    }
}

// Новая структура для выбора цветов циферблата
struct ColorSettingsView: View {
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var tempLightModeClockFaceColor: Color = .white
    @State private var tempDarkModeClockFaceColor: Color = .black
    
    var body: some View {
        List {
            Section(header: Text("Предпросмотр")) {
                HStack {
                    Spacer()
                    PreviewClockFaceView(backgroundColor: isDarkMode ? tempDarkModeClockFaceColor : tempLightModeClockFaceColor)
                        .frame(width: UIScreen.main.bounds.width * 0.55, height: UIScreen.main.bounds.width * 0.55)
                        .padding(.vertical, 10)
                    Spacer()
                }
            }
            
            Section(header: Text("Внешний вид")) {
                ColorPicker("Цвет циферблата (светлая тема)", selection: $tempLightModeClockFaceColor)
                    .onChange(of: tempLightModeClockFaceColor) { _, newValue in
                        lightModeClockFaceColor = newValue.toHex()
                    }
                ColorPicker("Цвет циферблата (темная тема)", selection: $tempDarkModeClockFaceColor)
                    .onChange(of: tempDarkModeClockFaceColor) { _, newValue in
                        darkModeClockFaceColor = newValue.toHex()
                    }
                
                Toggle("Темная тема", isOn: $isDarkMode)
            }
        }
        .onAppear {
            tempLightModeClockFaceColor = Color(hex: lightModeClockFaceColor) ?? .white
            tempDarkModeClockFaceColor = Color(hex: darkModeClockFaceColor) ?? .black
        }
    }
}

struct PreviewClockFaceView: View {
    let backgroundColor: Color
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var currentDate = Date()
    
    var body: some View {
        ZStack {
            // Фон циферблата
            Circle()
                .fill(backgroundColor)
            
            // Темное внешнее кольцо
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
            
            // Используем существующие компоненты и�� ClockView
            MainClockMarksView()
                .scaleEffect(0.8)
            
            MainClockHandView(currentDate: currentDate)
                .scaleEffect(0.8)
        }
        .frame(width: UIScreen.main.bounds.width * 0.5, height: UIScreen.main.bounds.width * 0.5)
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
