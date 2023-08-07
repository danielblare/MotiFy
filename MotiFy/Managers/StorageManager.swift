//
//  StorageManager.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import Foundation
import FirebaseStorage
import FirebaseStorageCombineSwift

final actor StorageManager {
    
    private let storage = Storage.storage()
    
    func get(from url: String) async throws -> URL {
        try await storage
            .reference(forURL: url)
            .downloadURL()
    }
    
}
