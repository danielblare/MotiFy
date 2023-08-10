//
//  Track.swift
//  MotiFy
//
//  Created by Daniel on 8/10/23.
//

import Foundation
import AVKit

struct FirestoreTrackModel: Codable {
    let id: String
    let title: String
    let genre: String
    let audio: String
    let artwork: String
    let description: String
    
    static let testInstance = FirestoreTrackModel(id: "yKjoNS0o5YkgFSIADjPF", title: "Test Title", genre: "Test genge", audio: "https://download.xn--41a.wiki/cache/2/3db/526816593_456239896.mp3?filename=Yeat-G%C3%ABt%20Busy.mp3", artwork: "https://www.udiscovermusic.com/wp-content/uploads/2022/04/2-Alive-Geek-Pack_-Explicit-Cover-2.jpg", description: "Test description")
}

struct Track: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let genre: String
    let audio: URL
    let artwork: URL
    let description: String
    let duration: CMTime
    
    init(id: String, title: String, genre: String, audio: URL, artwork: URL, description: String, duration: CMTime) {
        self.id = id
        self.title = title
        self.genre = genre
        self.audio = audio
        self.artwork = artwork
        self.description = description
        self.duration = duration
    }
    
    init(from model: FirestoreTrackModel, storageManager manager: StorageManager) async throws {
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = try await manager.get(from: model.audio)
        self.artwork = try await manager.get(from: model.artwork)
        self.duration = try await AVURLAsset(url: audio).load(.duration)
    }
    
    init(from model: FirestoreTrackModel) async throws {
        guard let audioURL = URL(string: model.audio),
              let artworkURL = URL(string: model.artwork) else { throw URLError(.badURL) }
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = audioURL
        self.artwork = artworkURL
        self.duration = try await AVURLAsset(url: audio).load(.duration)
    }
    
    static let offlineInstance = Track(id: "DHA4WlsFJMJCfCK1DTu3", title: "Title", genre: "Genre", audio: URL(string: "https://youtu.be/T_ASKLftsLs")!, artwork: URL(string: "https://lelolobi.com/wp-content/uploads/2021/11/Test-Logo-Small-Black-transparent-1-1.png")!, description: "Description", duration: CMTime(seconds: 60 * 59, preferredTimescale: 600))
}
