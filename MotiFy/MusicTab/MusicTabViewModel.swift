//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import Foundation
import AVKit

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    @Published private(set) var tracks: [Track] = []
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: CMTime = .zero

    private var player: AVPlayer
    
    private var trackPlayingID: Track.ID? = "yKjoNS0o5YkgFSIADjPF"
    
    var trackPlaying: Track? {
        self.tracks.first(where: { $0.id == trackPlayingID })
    }
    
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
            do {
                let trackModels: [FirestoreTrackModel] = try await dependencies.firestoreManager.get()
                var tracks: [Track] = []
                
                for model in trackModels {
                    tracks.append(try await Track(from: model))
                }
                
                if tracks != self.tracks, !tracks.isEmpty {
                    self.tracks = tracks
                    
                    let data = try JSONEncoder().encode(tracks)
                    UserDefaults.standard.setValue(data, forKey: "tracks")
                }
            } catch {
                print(error)
            }
        }
    }
        
    func play(_ track: Track) {
        if player.currentItem == nil || trackPlayingID != track.id {
            player.pause()
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
    
    func prev() {
        if currentTime.seconds > 2 {
            startAgain()
        } else {
            previousTrack()
        }
    }
    
    func skipTo(_ time: CMTime) async {
        await player.seek(to: time)
    }
    
    private func startAgain() {
        player.seek(to: .zero)
    }
    
    private func previousTrack() {
        guard let trackPlaying, let index = tracks.firstIndex(of: trackPlaying) else { return }
        play(tracks[(index - 1 + tracks.count) % tracks.count])
    }
    
    func next() {
        guard let trackPlaying, let index = tracks.firstIndex(of: trackPlaying) else { return }
        play(tracks[(index + 1) % tracks.count])
    }
}
