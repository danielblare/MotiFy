//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import SwiftUI
import AVKit

struct QueueElement: Equatable, Identifiable {
    let id: String
    let track: Track
    let autoplay: Bool
    
    init(track: Track, autoplay: Bool = false) {
        self.track = track
        self.id = track.id
        self.autoplay = autoplay
    }
}

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    enum RepeatOption: Codable, Hashable {
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
    
    @Published private(set) var queue: [QueueElement] = []
    
    @Published private(set) var repeatOption: RepeatOption = .dontRepeat {
        didSet {
            if repeatOption != oldValue {
                UserDefaults.standard.setValue(try? JSONEncoder().encode(repeatOption), forKey: "repeat_option")
            }
        }
    }
    @Published private(set) var autoplay: Bool {
        didSet {
            if autoplay != oldValue {
                UserDefaults.standard.setValue(autoplay, forKey: "autoplay")
            }
        }
    }

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
    
    private var trackPlayingID: Track.ID? {
        didSet {
            if trackPlayingID != oldValue {
                UserDefaults.standard.set(trackPlayingID, forKey: "track_playing_id")
            }
        }
    }
    
    var trackPlaying: Track? {
        self.tracks.first(where: { $0.id == trackPlayingID })
    }
    
    init(with dependencies: Dependencies) {
        self.player = AVPlayer()
        self.favorites = UserDefaults.standard.value(forKey: "favorites") as? [Track.ID] ?? []

        if let data = UserDefaults.standard.data(forKey: "repeat_option"),
           let option = try? JSONDecoder().decode(RepeatOption.self, from: data) {
            self.repeatOption = option
        }

        self.autoplay = UserDefaults.standard.bool(forKey: "autoplay")
        
        self.trackPlayingID = UserDefaults.standard.value(forKey: "track_playing_id") as? Track.ID
        
        if let data = UserDefaults.standard.data(forKey: "tracks"),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.tracks = tracks
        }

        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            Task { @MainActor in
                self.currentTime = time
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)

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
    
    func clearQueue() {
        withAnimation {
            queue.removeAll()
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
        guard let index = queue.firstIndex(where: { $0.track == track }) else { return }
        queue.remove(at: index)
    }
    
    func nextRepeatOption() {
        switch repeatOption {
        case .dontRepeat: repeatOption = .repeatAll
        case .repeatAll: repeatOption = .repeatOne
        case .repeatOne: repeatOption = .dontRepeat
        }
    }
    
    func addToStart(_ track: QueueElement) {
        queue.insert(track, at: 0)
    }
    
    func addToEnd(_ track: QueueElement) {
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
        checkAutoplay()
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
    
    func toggleAutoplay() {
        autoplay.toggle()
        if autoplay {
            checkAutoplay()
        } else {
            queue.removeAll(where: { $0.autoplay == true })
        }
    }
    
    func skipTo(_ time: CMTime) async {
        await player.seek(to: time)
    }
    
    private func startAgain() {
        player.seek(to: .zero)
    }
    
    private func previousTrack() {
        guard let current = trackPlaying, let prevTrack = history.popLast() else { return }
        addToStart(QueueElement(track: current))
        play(prevTrack)
    }
    
    private func moveCurrentTrackToHistory() {
        guard let currentTrack = trackPlaying else { return }
        history.append(currentTrack)
        if repeatOption == .repeatAll {
            queue.append(QueueElement(track: currentTrack))
        }
    }
    
    private func checkAutoplay() {
        guard autoplay, queue.isEmpty, let trackPlaying else { return }
        if let index = tracks.firstIndex(of: trackPlaying) {
            let newElement = QueueElement(track: tracks[(index + 1) % tracks.count], autoplay: true)
            addToStart(newElement)
        } else if let random = tracks.randomElement() {
            let newElement = QueueElement(track: random, autoplay: true)
            addToStart(newElement)
        } else {
            let newElement = QueueElement(track: trackPlaying, autoplay: true)
            addToStart(newElement)
        }
    }
    
    func next() {
        guard let nextTrackFromQueue = queue.first?.track else {
            startAgain()
            player.pause()
            isPlaying = false
            return
        }
        moveCurrentTrackToHistory()
        deleteFirstTrackFromQueue(track: nextTrackFromQueue)
        play(nextTrackFromQueue)
    }
}
