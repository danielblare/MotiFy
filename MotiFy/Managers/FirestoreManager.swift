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

final actor FirestoreManager {
    
    private let database = Firestore.firestore()
    
    func get<T: Decodable>() async throws -> T {
        switch T.self {
        case is [FirestoreTrackModel].Type:
            return try await database
                .collection("tracks")
                .getDocuments()
                .documents.map({ try $0.data(as: FirestoreTrackModel.self) }) as! T
        default: throw FirestoreErrorCode(.unimplemented)
        }
    }
}
