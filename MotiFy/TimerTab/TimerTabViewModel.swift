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

    // Activities
    @Published private var selectedActivityID: Activity.ID? {
        didSet {
            if selectedActivityID != oldValue {
                UserDefaults.standard.setValue(selectedActivityID, forKey: "selected_activity_id")
            }
        }
    }
    var selectedActivity: Activity? {
        activities.first(where: { $0.id == selectedActivityID })
    }
    @Published var activities: [Activity] = [] {
        didSet {
            if activities != oldValue, let data = try? JSONEncoder().encode(activities) {
                UserDefaults.standard.setValue(data, forKey: "activities")
            }
        }
    }
    
    @Published private(set) var badge: Int = 0
    
    private var onScreen: Bool = true
    
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
        
        if let selectedActivity {
            selectedTime = selectedActivity.defaultTime
        }
        
        Task {
            try? await NotificationService.shared.requestAuthorization()
        }
        
        NotificationService.shared.removeAllPendingNotifications()
                
        if let backgroundTime = UserDefaults.standard.object(forKey: "BackgroundTime") as? Date,
           let storedRemainingTime = UserDefaults.standard.object(forKey: "RemainingTime") as? TimeInterval {
            
            let timeInBackground = Date().timeIntervalSince(backgroundTime)
            let updatedRemainingTime = max(storedRemainingTime - timeInBackground, 0)
            if updatedRemainingTime > 0 {
                selectedTime = Time(from: updatedRemainingTime)
                startTimer()
            }
            
            UserDefaults.standard.removeObject(forKey: "BackgroundTime")
            UserDefaults.standard.removeObject(forKey: "RemainingTime")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func disappearing() {
        onScreen = false
    }
    
    func appearing() {
        onScreen = true
        badge = 0
    }
    
    @objc private func appDidEnterBackground() {
        if isTimerRunning {
            UserDefaults.standard.set(Date(), forKey: "BackgroundTime")
            UserDefaults.standard.set(remainingTime.timeInterval, forKey: "RemainingTime")
                        
            let date = Date().addingTimeInterval(remainingTime.timeInterval)
            Task {
                try? await NotificationService.shared.scheduleNotification(for: date, activity: selectedActivity)
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
        selectedTime = .init()
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
                    if !self.onScreen {
                        self.badge = 1
                    }
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

