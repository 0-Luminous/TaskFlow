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
    @AppStorage("backgroundColor") private var backgroundColor = Color.white.toHex()
    
    @State private var tempBackgroundColor = Color.white
    
    enum SortOption: String, CaseIterable, Identifiable {
        case startTime = "Началу"
        case title = "Заголовку"
        case category = "Категории"
        
        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Внешний вид")) {
                    Toggle("Темная тема", isOn: $isDarkMode)
                    ColorPicker("Цвет фона", selection: $tempBackgroundColor)
                        .onChange(of: tempBackgroundColor) { oldValue, newValue in
                            backgroundColor = newValue.toHex()
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
        }
        .onAppear {
            tempBackgroundColor = Color(hex: backgroundColor)
        }
    }
    
    private func resetSettings() {
        isDarkMode = false
        notificationsEnabled = true
        sortOption = SortOption.startTime.rawValue
        backgroundColor = Color.white.toHex()
        tempBackgroundColor = .white
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
