//
//  TimerTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/5/23.
//

import SwiftUI

/// A view for the Timer tab, allowing users to set and manage timers.
struct TimerTabView: View {
    
    /// The view model managing the Timer tab.
    @StateObject private var viewModel: TimerTabViewModel = TimerTabViewModel()
    
    /// Flag to indicate whether the categories editor sheet should be shown.
    @State private var showCategoriesEditor: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                // Activity Picker or Timer Display
                if !viewModel.showTimer {
                    Menu {
                        // Menu items for selecting activities
                        ForEach(viewModel.activities) { activity in
                            Button {
                                if viewModel.selectedActivity == activity {
                                    viewModel.unselect()
                                } else {
                                    viewModel.select(activity)
                                }
                            } label: {
                                Label(activity.name, systemImage: viewModel.selectedActivity == activity ? "checkmark" : "")
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            showCategoriesEditor = true
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                    } label: {
                        // Menu label indicating selected activity
                        HStack {
                            Text("Activity: \(viewModel.selectedActivity?.name ?? "None")")
                            
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    .tint(.secondary)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    // Timer Display
                    Text(viewModel.selectedActivity?.displayText ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                // Time Picker or Timer Display
                Group {
                    if viewModel.showTimer {
                        // Timer Display
                        Text(viewModel.remainingTime.formatted)
                            .font(.system(size: 70))
                            .monospacedDigit()
                    } else {
                        // Time Picker
                        HStack(spacing: 0) {
                            // Hours Picker
                            Picker("Hours", selection: $viewModel.selectedTime.hours) {
                                ForEach(0..<24) {
                                    Text("\($0)")
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Text("h")
                                    .padding(.trailing)
                            }
                            
                            // Minutes Picker
                            Picker("Minutes", selection: $viewModel.selectedTime.minutes) {
                                ForEach(0..<60) {
                                    Text("\($0)")
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Text("m")
                                    .padding(.trailing)
                            }
                            
                            // Seconds Picker
                            Picker("Seconds", selection: $viewModel.selectedTime.seconds) {
                                ForEach(0..<60) {
                                    Text("\($0)")
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Text("s")
                                    .padding(.trailing)
                            }
                            
                        }
                        .pickerStyle(.inline)
                        .monospacedDigit()
                    }
                }
                .frame(height: 300)
                
                // Timer Controls
                HStack {
                    Button("Cancel", role: .destructive) {
                        viewModel.cancelTimer()
                    }
                    .disabled(viewModel.isTimerRunning)
                    
                    Spacer(minLength: 0)
                    
                    Button(viewModel.isTimerRunning ? "Pause" : "Start") {
                        viewModel.isTimerRunning ? viewModel.pauseTimer() : viewModel.startTimer()
                    }
                    .foregroundStyle(viewModel.isTimerRunning ? .yellow : .green)
                }
                .buttonStyle(.bordered)
                .padding()
                .animation(nil, value: viewModel.showTimer)
                .animation(nil, value: viewModel.isTimerRunning)
                
                Spacer()
            }
            .padding()
            .animation(.bouncy, value: viewModel.showTimer)
            .background {
                if viewModel.isTimerRunning {
                    FancyBackground()
                        .blur(radius: 3)
                }
            }
            .animation(.bouncy, value: viewModel.isTimerRunning)
            .sheet(isPresented: $showCategoriesEditor) {
                NavigationStack {
                    List {
                        if !viewModel.activities.isEmpty {
                            ForEach(Array(viewModel.activities.enumerated()), id: \.element.id) { index, activity in
                                let binding = Binding<Activity> { viewModel.activities[index] } set: { viewModel.set($0, on: index) }
                                NavigationLink {
                                    ActivityEditor(for: binding)
                                } label: {
                                    Text(activity.name)
                                }

                            }
                            .onMove { set, index in
                                viewModel.move(from: set, to: index)
                            }
                            .onDelete { set in
                                viewModel.delete(on: set)
                            }
                        } else {
                            Text("No categories. Add one")
                                .foregroundStyle(.secondary)
                        }
                        
                        Section {
                            Button {
                                viewModel.create()
                            } label: {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            EditButton()
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .badge(viewModel.badge)
        .onAppear {
            viewModel.appearing()
        }
        .onDisappear {
            viewModel.disappearing()
        }
    }
}

#Preview {
    TimerTabView()
        .background {
            FancyBackground()
                .blur(radius: 3)
        }
}
