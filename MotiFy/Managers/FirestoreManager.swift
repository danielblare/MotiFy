//
//  FirestoreManager.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFirestoreCombineSwift

/// An actor managing Firestore interactions.
actor FirestoreManager {
    private let database = Firestore.firestore()
    
    /// Retrieve data of a specified type from Firestore.
    func get<T: Decodable>() async throws -> T {
        switch T.self {
        case is [FirestoreTrackModel].Type:
            // Retrieve and map FirestoreTrackModel data.
            return try await database
                .collection("tracks")
                .getDocuments()
                .documents.map({ try $0.data(as: FirestoreTrackModel.self) }) as! T
        default:
            // Throw an error for unimplemented types.
            throw FirestoreErrorCode(.unimplemented)
        }
    }
}
