//
//  HapticService.swift
//  MotiFy
//
//  Created by Daniel on 8/12/23.
//

import SwiftUI

/// Haptic engine service helps to integrate haptic feedback in your app
final class HapticService {
    
    /// Shared instance
    static let shared = HapticService()
    
    private init() {}
    
    /// Sends and impact
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    /// Sends a notification
    func notification(of type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
