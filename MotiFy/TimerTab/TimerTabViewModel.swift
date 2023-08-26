//
//  TimerTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import SwiftUI

/// A view model class for the Timer tab, responsible for managing timers and activities.
@MainActor
final class TimerTabViewModel: ObservableObject {
    
    /// The active timer instance.
    private var timer: Timer? = nil
    
    /// Flag to indicate whether the timer is currently running.
    @Published private(set) var isTimerRunning = false
    
    /// Flag to indicate whether the timer display should be shown.
    @Published private(set) var showTimer = false
    
    /// The selected time for the timer.
    @Published var selectedTime: Time = .init()
    
    /// The remaining time on the timer.
    @Published private(set) var remainingTime: Time = .init() {
        didSet {
            print(remainingTime)
        }
    }
    
    /// The ID of the selected activity.
    @Published private var selectedActivityID: Activity.ID? {
        didSet {
            if selectedActivityID != oldValue {
                UserDefaults.standard.setValue(selectedActivityID, forKey: "selected_activity_id")
            }
        }
    }
    
    /// The selected activity.
    var selectedActivity: Activity? {
        activities.first(where: { $0.id == selectedActivityID })
    }
    
    /// The list of available activities.
    @Published var activities: [Activity] = [] {
        didSet {
            if activities != oldValue, let data = try? JSONEncoder().encode(activities) {
                UserDefaults.standard.setValue(data, forKey: "activities")
            }
        }
    }
    
    /// The badge count for notifications.
    @Published private(set) var badge: Int = 0
    
    /// Flag to indicate whether the app is currently on screen.
    private var onScreen: Bool = true
    
    /// Initializes the view model.
    init() {
        // Load activities from user defaults if available
        if let data = UserDefaults.standard.data(forKey: "activities"),
           let activities = try? JSONDecoder().decode([Activity].self, from: data) {
            self.activities = activities
        }
        
        // Load selected activity ID from user defaults if available
        if let id = UserDefaults.standard.string(forKey: "selected_activity_id") {
            if self.activities.contains(where: { $0.id == id }) {
                self.selectedActivityID = id
            } else {
                UserDefaults.standard.removeObject(forKey: "selected_activity_id")
            }
        }
        
        // Set selected time to default time of the selected activity
        if let selectedActivity {
            selectedTime = selectedActivity.defaultTime
        }
        
        // Request notification authorization
        Task {
            try? await NotificationService.shared.requestAuthorization()
        }
        
        // Clear pending notifications
        NotificationService.shared.removeAllPendingNotifications()
        
        // Handle background timer continuation
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
        
        // Register for background notification
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Register for foreground notification
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// Notifies the view model that the view is disappearing.
    func disappearing() {
        onScreen = false
    }
    
    /// Notifies the view model that the view is appearing.
    func appearing() {
        onScreen = true
        badge = 0
        NotificationService.shared.removeAllDeliveredNotifications()
    }
    
    @objc private func appWillEnterForeground() {
        print("foregrounding")
        NotificationService.shared.removeAllPendingNotifications()
        
        if let backgroundTime = UserDefaults.standard.object(forKey: "BackgroundTime") as? Date,
           let storedRemainingTime = UserDefaults.standard.object(forKey: "RemainingTime") as? TimeInterval {
            
            let timeInBackground = Date().timeIntervalSince(backgroundTime)
            let updatedRemainingTime = max(storedRemainingTime - timeInBackground, 0)
            
            if updatedRemainingTime > 0 {
                remainingTime = Time(from: updatedRemainingTime)
            } else {
                cancelTimer()
            }
            
            UserDefaults.standard.removeObject(forKey: "BackgroundTime")
            UserDefaults.standard.removeObject(forKey: "RemainingTime")
        }
    }
    
    /// Handles the app entering the background by saving timer state and scheduling notifications.
    @objc private func appDidEnterBackground() {
        print("backgrounding")
        if isTimerRunning {
            UserDefaults.standard.set(Date(), forKey: "BackgroundTime")
            UserDefaults.standard.set(remainingTime.timeInterval, forKey: "RemainingTime")
            
            let date = Date().addingTimeInterval(remainingTime.timeInterval)
            Task {
                NotificationService.shared.removeAllPendingNotifications()
                try? await NotificationService.shared.scheduleNotification(for: date, activity: selectedActivity)
            }
        }
    }
    
    /// Deletes the activity at the specified index set.
    func delete(on set: IndexSet) {
        withAnimation {
            activities.remove(atOffsets: set)
        }
    }
    
    /// Clears the selected activity and time.
    func unselect() {
        selectedActivityID = nil
        selectedTime = .init()
    }
    
    /// Moves an activity from one index set to another index.
    func move(from set: IndexSet, to index: Int) {
        activities.move(fromOffsets: set, toOffset: index)
    }
    
    /// Selects the specified activity and sets its default time.
    func select(_ activity: Activity) {
        selectedActivityID = activity.id
        selectedTime = activity.defaultTime
    }
    
    /// Sets the specified activity at the specified index.
    func set(_ activity: Activity, on index: Int) {
        activities[index] = activity
    }
    
    /// Creates a new activity with default values and appends it to the list.
    func create() {
        let newActivity = Activity(name: "New activity", displayText: "New activity")
        withAnimation {
            activities.append(newActivity)
        }
    }
    
    /// Starts the timer with the selected time.
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
    
    /// Cancels the running timer.
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        showTimer = false
    }
    
    /// Pauses the running timer.
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
}
