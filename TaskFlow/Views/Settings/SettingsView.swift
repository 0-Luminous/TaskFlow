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
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        sortOption = SortOption.startTime.rawValue
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
                    ZStack {
                        Circle()
                            .fill(isDarkMode ? tempDarkModeClockFaceColor : tempLightModeClockFaceColor)
                            .frame(width: 200, height: 200)
                        
                        // Маркеры часов
                        ForEach(0..<24) { hour in
                            MainClockMarker(hour: hour)
                                .frame(width: 200, height: 200)
                        }
                        
                        // Стрелка часов
                        MainClockHandView(currentDate: Date())
                            .frame(width: 200, height: 200)
                    }
                    Spacer()
                }
                .padding(.vertical)
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
