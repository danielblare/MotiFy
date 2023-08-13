//
//  MotiFyApp.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI
import Firebase

final class Dependencies {
    let firestoreManager: FirestoreManager
    let storageManager: StorageManager
    let cacheManager: CacheManager
    
    init() {
        self.firestoreManager = FirestoreManager()
        self.storageManager = StorageManager()
        self.cacheManager = CacheManager()
    }
    
    static let testInstance = Dependencies()
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct MotiFyApp: App {
    
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    private let dependencies: Dependencies
    
    /// Showing the launch screen when app starts
    @State private var showLaunchView: Bool = true
    
    init() {
        
        FirebaseApp.configure()
        
        self.dependencies = Dependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            if showLaunchView {
                LaunchView($showLaunchView)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
                    .zIndex(1.0)
            } else {
                ContentView(with: dependencies)
                
            }
        }
    }
}
