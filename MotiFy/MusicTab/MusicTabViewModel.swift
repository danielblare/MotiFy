//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import Foundation
import AVKit

struct Track: Codable, Identifiable {
    let id: String
    let title: String
    let genre: String
    let audio: URL
    let artwork: URL
    let description: String
    let duration: CMTime
    
    init(from model: FirestoreTrackModel) async throws {
        let manager = StorageManager()
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = try await manager.get(from: model.audio)
        self.artwork = try await manager.get(from: model.artwork)
        self.duration = try await AVURLAsset(url: audio).load(.duration)
    }
}

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    private var player: AVPlayer
    
    @Published private(set) var trackPlaying: Track.ID?// = "yKjoNS0o5YkgFSIADjPF"
    
    @Published private(set) var tracks: [Track] = []
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: CMTime = .zero
    
    init() {
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
            if let trackModels = try? await FirestoreManager.shared.getTracks() {

                var tracks: [Track] = []
                
                for model in trackModels {
                    if let track = try? await Track(from: model) {
                        tracks.append(track)
                    }
                }
                self.tracks = tracks
                
                if let data = try? JSONEncoder().encode(tracks) {
                    UserDefaults.standard.setValue(data, forKey: "tracks")
                }
            }
        }
    }
    
    func play(_ track: Track) {
        let playerItem = AVPlayerItem(url: track.audio)
        player.replaceCurrentItem(with: playerItem)
        trackPlaying = track.id
        play()
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func getTrack(by id: Track.ID) -> Track? {
        self.tracks.first(where: { $0.id == id })
    }
}
