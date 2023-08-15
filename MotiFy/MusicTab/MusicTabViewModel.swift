//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import SwiftUI
import AVKit
import MediaPlayer

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
    
    private let cacheManager: CacheManager
    
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
        
        self.cacheManager = dependencies.cacheManager
        
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
        
        UIApplication.shared.beginReceivingRemoteControlEvents()

        setupRemoteTransportControls()
        
        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            Task { @MainActor in
                self.currentTime = time
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        Task {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
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
            try? next()
        }
    }
    
    private func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [weak self] event in
            if let self, let track = self.trackPlaying {
                self.play(track)
                return .success
            }
            return .noSuchContent
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            if let self {
                self.pause()
                return .success
            }
            return .noSuchContent
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            if let self {
                do {
                    try self.next()
                    return .success
                } catch {
                    return .noSuchContent
                }
            }
            return .noSuchContent
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            if let self {
                do {
                    try self.prev()
                    return .success
                } catch {
                    return .noSuchContent
                }
            }
            return .noSuchContent
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent, let self {
                // Handle the playback position change here
                let newPosition = event.positionTime
                Task {
                    let time: CMTime = .init(seconds: newPosition, preferredTimescale: 600)
                    print(time)
                    await self.skipTo(time)
                }
                return .success
            }
            return .commandFailed
        }
    }
    
    private func configurePlayingInfo(for track: Track) {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyGenre] = track.genre
        nowPlayingInfo[MPMediaItemPropertyAssetURL] = track.audio
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate


        if let savedImage = cacheManager.getFrom(cacheManager.artWorkCache, forKey: track.id) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: savedImage.size) { _ in
                savedImage
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else {
            Task {
                if let data = try? await URLSession.shared.data(from: track.artwork).0,
                   let image = UIImage(data: data) {
                    cacheManager.addTo(cacheManager.artWorkCache, forKey: track.id, value: image)
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                        image
                    }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
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
        configurePlayingInfo(for: track)
        isPlaying = true
        checkAutoplay()
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func prev() throws {
        if currentTime.seconds > 2 {
            startAgain()
        } else {
            try previousTrack()
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
    
    private func previousTrack() throws {
        guard let current = trackPlaying, let prevTrack = history.popLast() else { throw PlayerError.noPrevTrackInHistory }
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
    
    func next() throws {
        guard let nextTrackFromQueue = queue.first?.track else {
            startAgain()
            player.pause()
            isPlaying = false
            throw PlayerError.noNextTrackInQueue
        }
        moveCurrentTrackToHistory()
        deleteFirstTrackFromQueue(track: nextTrackFromQueue)
        play(nextTrackFromQueue)
    }
    
    enum PlayerError: Error {
        case noPrevTrackInHistory
        case noNextTrackInQueue
    }
}
