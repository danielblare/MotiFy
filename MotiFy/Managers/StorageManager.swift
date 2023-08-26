//
//  StorageManager.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import Foundation
import FirebaseStorage
import FirebaseStorageCombineSwift

/// An actor responsible for managing interactions with Firebase Cloud Storage.
actor StorageManager {
    private let storage = Storage.storage()
    
    /// Retrieve a download URL for a file stored in Firebase Cloud Storage.
    /// - Parameter url: The storage URL of the file.
    /// - Returns: A URL pointing to the downloadable content.
    /// - Throws: An error if the download URL cannot be obtained.
    func get(from url: String) async throws -> URL {
        try await storage
            .reference(forURL: url)
            .downloadURL()
    }
}
