//
//  TimerTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/5/23.
//

import SwiftUI

struct TimerTabView: View {
    
    @StateObject private var viewModel: TimerTabViewModel = TimerTabViewModel()
    
    @State private var showCategoriesEditor: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                if !viewModel.showTimer {
                    Menu {
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
                        HStack {
                            Text("Activity: \(viewModel.selectedActivity?.name ?? "None")")
                            
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    .tint(.secondary)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(viewModel.selectedActivity?.displayText ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                
                Group {
                    if viewModel.showTimer {
                        Text(viewModel.remainingTime.formatted)
                            .font(.system(size: 70))
                            .monospacedDigit()
                    } else {
                        HStack(spacing: 0) {
                            Picker("Hours", selection: $viewModel.selectedTime.hours) {
                                ForEach(0..<24) {
                                    Text("\($0)")
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Text("h")
                                    .padding(.trailing)
                            }
                            
                            Picker("Minutes", selection: $viewModel.selectedTime.minutes) {
                                ForEach(0..<60) {
                                    Text("\($0)")
                                }
                            }
                            .overlay(alignment: .trailing) {
                                Text("m")
                                    .padding(.trailing)
                            }
                            
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
                    }
                }
                .frame(height: 300)
                
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
    }
}

#Preview {
    TimerTabView()
        .background {
            FancyBackground()
                .blur(radius: 3)
        }
}
