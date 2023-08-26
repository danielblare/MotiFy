//
//  MusicTabViewModel.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import SwiftUI
import AVKit
import MediaPlayer

/// A view model responsible for managing the music playback and queue.
@MainActor
final class MusicTabViewModel: ObservableObject {
    // Dependencies
    private let cacheManager: CacheManager
    private let firestoreManager: FirestoreManager
        
    /// Enumeration to define different repeat options for music playback.
    enum RepeatOption: Codable, Hashable {
        case dontRepeat
        case repeatAll
        case repeatOne
        
        /// Icon representing the repeat option.
        var icon: Image {
            switch self {
            case .dontRepeat:
                return Image(systemName: "repeat")
            case .repeatAll:
                return Image(systemName: "repeat")
            case .repeatOne:
                return Image(systemName: "repeat.1")
            }
        }
    }
    
    /// Published property to store the current queue of QueueElements.
    @Published private(set) var queue: [QueueElement] = []
    
    /// Published property to store the current repeat option.
    @Published private(set) var repeatOption: RepeatOption = .dontRepeat {
        didSet {
            if repeatOption != oldValue {
                UserDefaults.standard.setValue(try? JSONEncoder().encode(repeatOption), forKey: "repeat_option")
            }
        }
    }
    
    /// Published property to store the autoplay flag.
    @Published private(set) var autoplay: Bool {
        didSet {
            if autoplay != oldValue {
                UserDefaults.standard.setValue(autoplay, forKey: "autoplay")
            }
        }
    }
    
    /// Published property to store the list of available tracks.
    @Published private(set) var tracks: [Track] = []
    
    /// Published property to store the list of favorite track IDs.
    @Published private(set) var favorites: [Track.ID] {
        didSet {
            if favorites != oldValue {
                UserDefaults.standard.setValue(favorites, forKey: "favorites")
            }
        }
    }
    
    /// Published property to indicate if music is currently playing.
    @Published private(set) var isPlaying: Bool = false
    
    /// Published property to store the current playback time.
    @Published private(set) var currentTime: CMTime = .zero
    
    /// A list to store track history.
    private var history: [Track] = []
    
    /// The AVPlayer instance for music playback.
    private var player: AVPlayer
    
    /// Property to store the ID of the currently playing track.
    private var trackPlayingID: Track.ID? {
        didSet {
            if trackPlayingID != oldValue {
                UserDefaults.standard.set(trackPlayingID, forKey: "track_playing_id")
            }
        }
    }
    
    /// Computed property to retrieve the currently playing Track based on its ID.
    var trackPlaying: Track? {
        self.tracks.first(where: { $0.id == trackPlayingID })
    }
    
    /// Initializes the MusicPlayer with the given dependencies.
    /// - Parameter dependencies: An instance of Dependencies containing required managers.
    init(with dependencies: Dependencies) {
        // Injecting dependencies
        self.cacheManager = dependencies.cacheManager
        self.firestoreManager = dependencies.firestoreManager
        
        // Initializing AVPlayer for music playback
        self.player = AVPlayer()
        
        // Loading favorites from UserDefaults
        self.favorites = UserDefaults.standard.value(forKey: "favorites") as? [Track.ID] ?? []
        
        // Loading repeat option from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "repeat_option"),
           let option = try? JSONDecoder().decode(RepeatOption.self, from: data) {
            self.repeatOption = option
        }
        
        // Loading autoplay flag from UserDefaults
        self.autoplay = UserDefaults.standard.bool(forKey: "autoplay")
        
        // Loading currently playing track ID from UserDefaults
        self.trackPlayingID = UserDefaults.standard.value(forKey: "track_playing_id") as? Track.ID
        
        // Loading tracks from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "tracks"),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.tracks = tracks
        }
        
        // Begin receiving remote control events
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Setup remote transport controls (e.g., play, pause) for external controls
        setupRemoteTransportControls()
        
        // Add periodic time observer for updating current playback time
        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            Task { @MainActor in
                self.currentTime = time
            }
        }
        
        // Register observer for playback completion
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Set the audio session category to playback
        Task {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        }
        
        // Fetch track data from Firestore and initialize Track objects
        Task {
            do {
                let trackModels: [FirestoreTrackModel] = try await dependencies.firestoreManager.get()
                var tracks: [Track] = []
                
                for model in trackModels {
                    tracks.append(try await Track(from: model))
                }
                
                // Update tracks and save to UserDefaults
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
    
    /// Refreshes the list of tracks by fetching data from Firestore.
    func refresh() async {
        do {
            // Fetch FirestoreTrackModels from Firestore
            let trackModels: [FirestoreTrackModel] = try await firestoreManager.get()
            var tracks: [Track] = []
            
            // Convert FirestoreTrackModels to Track objects
            for model in trackModels {
                tracks.append(try await Track(from: model))
            }
            
            // Update tracks and save to UserDefaults
            if tracks != self.tracks, !tracks.isEmpty {
                self.tracks = tracks
                
                let data = try JSONEncoder().encode(tracks)
                UserDefaults.standard.setValue(data, forKey: "tracks")
            }
        } catch {
            print(error)
        }
    }
    
    /// Called when an item finishes playing, handles repeat options.
    @objc private func itemDidFinishPlaying(_ notification: Notification) {
        if repeatOption == .repeatOne {
            playAgain()
        } else {
            try? next()
        }
    }
    
    /// Sets up remote transport controls for external playback control.
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
        
        // Add handler for Next Track Command
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
        
        // Add handler for Previous Track Command
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
        
        // Add handler for Playback Position Change Command
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
    
    /// Configures the now playing info for the currently playing track.
    private func configureTrackInfo() {
        guard let track = trackPlaying else { return }
        var nowPlayingInfo = [String: Any]()
        
        // Set metadata for now playing info
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.author
        nowPlayingInfo[MPMediaItemPropertyAssetURL] = track.audio
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Try to retrieve artwork from cache, otherwise fetch it
        if let savedImage = cacheManager.getFrom(cacheManager.artWorkCache, forKey: track.id) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: savedImage.size) { _ in
                savedImage
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else {
            Task {
                if let data = try? await URLSession.shared.data(from: track.artwork).0,
                   let image = UIImage(data: data) {
                    // Add artwork to cache and update now playing info
                    cacheManager.addTo(cacheManager.artWorkCache, forKey: track.id, value: image)
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                        image
                    }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }
        }
    }
    
    /// Clears the queue of tracks.
    func clearQueue() {
        withAnimation {
            queue.removeAll()
        }
    }
    
    /// Moves an element within the queue from one position to another.
    func moveElementInQueue(from set: IndexSet, to index: Int) {
        queue.move(fromOffsets: set, toOffset: index)
    }
    
    /// Deletes elements from the queue at specified indexes.
    func deleteFromQueue(on set: IndexSet) {
        withAnimation {
            queue.remove(atOffsets: set)
        }
    }
    
    /// Deletes the first occurrence of a track from the queue.
    private func deleteFirstTrackFromQueue(track: Track) {
        // Find the index of the track in the queue and remove it
        guard let index = queue.firstIndex(where: { $0.track == track }) else { return }
        queue.remove(at: index)
    }
    
    /// Advances to the next repeat option in the sequence.
    func nextRepeatOption() {
        // Cycle through the repeat options
        switch repeatOption {
        case .dontRepeat: repeatOption = .repeatAll
        case .repeatAll: repeatOption = .repeatOne
        case .repeatOne: repeatOption = .dontRepeat
        }
    }
    
    /// Adds a track to the start of the queue.
    func addToStart(_ track: QueueElement) {
        queue.insert(track, at: 0)
    }
    
    /// Adds a track to the end of the queue.
    func addToEnd(_ track: QueueElement) {
        queue.append(track)
    }
    
    /// Sets the favorite status for a track.
    func setFavorite(to value: Bool, for track: Track) {
        // Add or remove track ID from favorites based on value
        if value == true {
            favorites.insert(track.id, at: 0)
        } else {
            favorites.removeAll(where: { $0 == track.id })
        }
    }
    
    /// Checks if a track is in the list of favorites.
    func isFavorite(_ track: Track) -> Bool {
        favorites.contains(track.id)
    }
    
    /// Restarts the currently playing track from the beginning.
    private func playAgain() {
        Task {
            await skipTo(.zero)
            player.play()
            configureTrackInfo()
            isPlaying = true
        }
    }
    
    /// Plays the specified track.
    func play(_ track: Track) {
        // Check if the player's current item is nil or the playing track is different
        if player.currentItem == nil || trackPlayingID != track.id {
            player.pause()
            let asset = AVAsset(url: track.audio)
            let playerItem = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: playerItem)
        }
        trackPlayingID = track.id
        player.play()
        configureTrackInfo()
        isPlaying = true
        checkAutoplay()
    }
    
    /// Pauses the player.
    func pause() {
        player.pause()
        configureTrackInfo()
        isPlaying = false
    }
    
    /// Skips to the previous track if current time is less than 2 seconds; otherwise, restarts the current track.
    func prev() throws {
        if currentTime.seconds > 2 {
            startAgain()
        } else {
            try previousTrack()
        }
    }
    
    /// Toggles the autoplay setting.
    func toggleAutoplay() {
        autoplay.toggle()
        if autoplay {
            checkAutoplay()
        } else {
            queue.removeAll(where: { $0.autoplay == true })
        }
    }
    
    /// Skips the player's playback to the specified time asynchronously.
    func skipTo(_ time: CMTime) async {
        await player.seek(to: time)
        configureTrackInfo()
    }
    
    /// Restarts the currently playing track from the beginning asynchronously.
    private func startAgain() {
        Task {
            await player.seek(to: .zero)
            configureTrackInfo()
        }
    }
    
    /// Moves the currently playing track to the history and plays the previous track in history.
    private func previousTrack() throws {
        guard let current = trackPlaying, let prevTrack = history.popLast() else {
            throw PlayerError.noPrevTrackInHistory
        }
        addToStart(QueueElement(track: current))
        play(prevTrack)
    }
    
    /// Moves the currently playing track to the history.
    private func moveCurrentTrackToHistory() {
        guard let currentTrack = trackPlaying else { return }
        history.append(currentTrack)
        if repeatOption == .repeatAll {
            queue.append(QueueElement(track: currentTrack))
        }
    }
    
    /// Checks if autoplay is enabled and adds a track to the queue if needed.
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
    
    /// Moves to the next track in the queue and plays it.
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
    
    /// Enumeration to represent errors that can occur in the player.
    enum PlayerError: Error {
        case noPrevTrackInHistory
        case noNextTrackInQueue
    }
    
}
