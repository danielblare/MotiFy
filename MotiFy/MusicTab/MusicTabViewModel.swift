//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import SwiftUI
import AVKit

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    enum RepeatOption {
        case dontRepeat
        case repeatAll
        case repeatOne
        
        var icon: Image {
            switch self {
            case .dontRepeat:
                Image(systemName: "repeat")
            case .repeatAll:
                Image(systemName: "repeat")
            case .repeatOne:
                Image(systemName: "repeat.1")
            }
        }
    }
    
    @Published private(set) var queue: [Track] = []
    
    @Published private(set) var repeatOption: RepeatOption = .dontRepeat

    @Published private(set) var tracks: [Track] = []
    @Published private(set) var favorites: [Track.ID] {
        didSet {
            if favorites != oldValue {
                UserDefaults.standard.setValue(favorites, forKey: "favorites")
            }
        }
    }

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: CMTime = .zero
    
    private var history: [Track] = []

    private var player: AVPlayer
    
    private var trackPlayingID: Track.ID? = "yKjoNS0o5YkgFSIADjPF"
    
    var trackPlaying: Track? {
        self.tracks.first(where: { $0.id == trackPlayingID })
    }
    
    init(with dependencies: Dependencies) {
        self.player = AVPlayer()
        self.favorites = UserDefaults.standard.value(forKey: "favorites") as? [Track.ID] ?? []

        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            Task { @MainActor in
                self.currentTime = time
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)

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
    
    @objc private func itemDidFinishPlaying(_ notification: Notification) {
        if repeatOption == .repeatOne {
            playAgain()
        } else {
            next()
        }
    }
    
    func moveElementInQueue(from set: IndexSet, to index: Int) {
        queue.move(fromOffsets: set, toOffset: index)
    }
    
    func deleteFromQueue(on set: IndexSet) {
        withAnimation {
            queue.remove(atOffsets: set)
        }
    }
    
    private func deleteFirstTrackFromQueue(track: Track) {
        guard let index = queue.firstIndex(of: track) else { return }
        history.append(queue.remove(at: index))
    }
    
    func nextRepeatOption() {
        switch repeatOption {
        case .dontRepeat: repeatOption = .repeatAll
        case .repeatAll: repeatOption = .repeatOne
        case .repeatOne: repeatOption = .dontRepeat
        }
    }
    
    func addToStart(_ track: Track) {
        queue.insert(track, at: 0)
    }
    
    func addToEnd(_ track: Track) {
        queue.append(track)
    }
    
    func setFavorite(to value: Bool, for track: Track) {
        if value == true {
            favorites.insert(track.id, at: 0)
        } else {
            favorites.removeAll(where: { $0 == track.id})
        }
    }
    
    func isFavorite(_ track: Track) -> Bool {
        favorites.contains(track.id)
    }
    
    private func playAgain() {
        Task {
            await skipTo(.zero)
            player.play()
            isPlaying = true
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
        guard let prevTrack = history.popLast() else { return }
        play(prevTrack)
    }
    
    func next() {
        guard let nextTrackFromQueue = queue.first else {
            isPlaying = false
            trackPlayingID = nil
            return
        }
        deleteFirstTrackFromQueue(track: nextTrackFromQueue)
        play(nextTrackFromQueue)
    }
}
