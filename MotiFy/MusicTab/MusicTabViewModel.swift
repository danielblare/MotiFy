//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import Foundation
import AVKit

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
    
    static let testInstance = Track(id: "yKjoNS0o5YkgFSIADjPF", title: "Test Title", genre: "Test genge", audio: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/motify-f7252.appspot.com/o/MorningMudd%2Faudio.mp3?alt=media&token=88b7a262-7df0-4c9e-b435-cea18a6f22ec")!, artwork: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/motify-f7252.appspot.com/o/MorningMudd%2Fartwork.png?alt=media&token=654a8ea0-5a02-48e7-924c-083a48b48918")!, description: "Test description", duration: CMTime(seconds: 60, preferredTimescale: 600))
    
    static let offlineInstance = Track(id: "DHA4WlsFJMJCfCK1DTu3", title: "Title", genre: "Genre", audio: URL(string: "https://youtu.be/T_ASKLftsLs")!, artwork: URL(string: "https://lelolobi.com/wp-content/uploads/2021/11/Test-Logo-Small-Black-transparent-1-1.png")!, description: "Description", duration: CMTime(seconds: 60 * 59, preferredTimescale: 600))
}

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    private var player: AVPlayer
    
    private var trackPlayingID: Track.ID? = "DHA4WlsFJMJCfCK1DTu3"
    
    var trackPlaying: Track? {
        self.tracks.first(where: { $0.id == trackPlayingID })
    }
    
    @Published private(set) var tracks: [Track] = [.offlineInstance]
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: CMTime = .zero
    
    init(with dependencies: Dependencies) {
        self.player = AVPlayer()
        
        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            Task { @MainActor in
                self.currentTime = time
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "tracks"),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.tracks = tracks
        }
        Task {
            if let trackModels = try? await dependencies.firestoreManager.getTracks() {

                var tracks: [Track] = []
                
                for model in trackModels {
                    if let track = try? await Track(from: model, storageManager: dependencies.storageManager) {
                        tracks.append(track)
                    }
                }
                if tracks != self.tracks, !tracks.isEmpty {
                    self.tracks = tracks
                    
                    if let data = try? JSONEncoder().encode(tracks) {
                        UserDefaults.standard.setValue(data, forKey: "tracks")
                    }
                }
            }
        }
    }
        
    func play(_ track: Track) {
        if player.currentItem == nil || trackPlayingID != track.id {
            let asset = AVAsset(url: track.audio)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
        }
        trackPlayingID = track.id
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
}
