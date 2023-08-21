//
//  NotificationService.swift
//  MotiFy
//
//  Created by Daniel on 8/20/23.
//

import UserNotifications
import UIKit

final class NotificationService {
        
    static let shared = NotificationService()
        
    @discardableResult
    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func scheduleNotification(for date: Date, activity: Activity?) async throws {
                
        let content = UNMutableNotificationContent()
        
        content.title = "Time is up"
        if let activity {
            content.subtitle = activity.name
        }
        content.sound = .default
        
        let components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
        try await UNUserNotificationCenter.current().add(request)
    }
}

