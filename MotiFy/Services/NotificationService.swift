//
//  NotificationService.swift
//  MotiFy
//
//  Created by Daniel on 8/20/23.
//

import UserNotifications
import UIKit

/// Service for User notification center
final class NotificationService {
        
    /// Shared instance
    static let shared = NotificationService()
        
    /// Requesting authorization to send notification
    @discardableResult
    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    /// Remove all pending (scheduled) notifications.
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Remove all delivered notifications.
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// Schedule a notification for a specific date and optional activity.
    func scheduleNotification(for date: Date, activity: Activity?) async throws {
        // Create notification content.
        let content = UNMutableNotificationContent()
        content.title = "Time is up"
        
        // Set activity name as subtitle if provided.
        if let activity {
            content.subtitle = activity.name
        }
        
        content.sound = .default
        
        // Create notification trigger based on date.
        let components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Generate unique identifier for the notification request.
        let requestIdentifier = UUID().uuidString
        
        // Create notification request.
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        // Try to add the notification request.
        try await UNUserNotificationCenter.current().add(request)
    }
}

