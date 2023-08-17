//
//  TimerTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import SwiftUI

@MainActor
final class TimerTabViewModel: ObservableObject {
    
    private var timer: Timer? = nil
    @Published private(set) var isTimerRunning = false
    @Published private(set) var showTimer = false

    @Published var selectedTime: Time = .init()
    @Published private(set) var remainingTime: Time = .init()

    @Published private var selectedActivityID: Activity.ID?
    var selectedActivity: Activity? {
        activities.first(where: { $0.id == selectedActivityID })
    }
    @Published var activities: [Activity] = []

    
    init() {
        if let data = UserDefaults.standard.data(forKey: "activities"),
           let activities = try? JSONDecoder().decode([Activity].self, from: data) {
            self.activities = activities
        }
        
        if let id = UserDefaults.standard.string(forKey: "selected_activity_id") {
            if self.activities.contains(where: { $0.id == id }) {
                self.selectedActivityID = id
            } else {
                UserDefaults.standard.removeObject(forKey: "selected_activity_id")
            }
        }
    }
    
    func delete(on set: IndexSet) {
        withAnimation {
            activities.remove(atOffsets: set)
        }
    }
    
    func unselect() {
        selectedActivityID = nil
    }
    
    func move(from set: IndexSet, to index: Int) {
        activities.move(fromOffsets: set, toOffset: index)
    }
    
    func select(_ activity: Activity) {
        selectedActivityID = activity.id
        selectedTime = activity.defaultTime
    }
    
    func set(_ activity: Activity, on index: Int) {
        activities[index] = activity
    }
    
    func create() {
        let newActivity = Activity(name: "New activity", displayText: "New activity")
        withAnimation {
            activities.append(newActivity)
        }
    }
    
    func startTimer() {
        guard timer == nil, selectedTime.timeInterval > 0 else {
            return
        }
        if !showTimer {
            remainingTime = selectedTime
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if self.remainingTime.timeInterval > 0 {
                    if self.remainingTime.seconds > 0 {
                        self.remainingTime.seconds -= 1
                        return
                    }
                    if self.remainingTime.minutes > 0 {
                        self.remainingTime.minutes -= 1
                        self.remainingTime.seconds = 59
                        return
                    }
                    if self.remainingTime.hours > 0 {
                        self.remainingTime.hours -= 1
                        self.remainingTime.minutes = 59
                        self.remainingTime.seconds = 59
                        return
                    }
                } else {
                    self.cancelTimer()
                }
            }
        }
        isTimerRunning = true
        showTimer = true
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        showTimer = false
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

}

