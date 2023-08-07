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

struct FirestoreTrackModel: Codable {
    let id: String
    let title: String
    let genre: String
    let audio: String
    let artwork: String
    let description: String
}


final actor FirestoreManager {
    
    static let shared = FirestoreManager()
    
    private init() {}
    
    private let database = Firestore.firestore()
    
    func getTracks() async throws -> [FirestoreTrackModel] {
        try await database
            .collection("tracks")
            .getDocuments()
            .documents
            .map({ try $0.data(as: FirestoreTrackModel.self) })
    }
    
    
}
