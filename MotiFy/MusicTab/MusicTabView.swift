//
//  MusicTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import AVKit
import SwiftUI

struct Track: Codable, Identifiable {
    let id: String
    let title: String
    let genre: String
    let audio: URL
    let artwork: URL
    let description: String
    
    init(from model: FirestoreTrackModel) async throws {
        let manager = StorageManager()
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = try await manager.get(from: model.audio)
        self.artwork = try await manager.get(from: model.artwork)
    }
}

@MainActor
final class MusicTabViewModel: ObservableObject {
    
    private var player = AVPlayer()
    @Published private(set) var trackPlaying: Track.ID?
    
    @Published private(set) var tracks: [Track] = []
    
    @Published private(set) var isPlaying: Bool = false
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "tracks"),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            self.tracks = tracks
            print(tracks)
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
        play()
        trackPlaying = track.id
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
}

struct MusicTabView: View {
    @StateObject private var viewModel = MusicTabViewModel()
    
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tracks) { track in
                    Button {
                        if viewModel.trackPlaying == track.id, viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            if viewModel.trackPlaying == track.id {
                                viewModel.play()
                            } else {
                                viewModel.play(track)
                            }
                        }
                    } label: {
                        HStack {
                            
                            AsyncImage(url: track.artwork) { image in
                                image
                                    .resizable()
                            } placeholder: {
                                Image("artwork")
                                    .resizable()
                            }
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .overlay {
                                if viewModel.trackPlaying == track.id {
                                    MusicPlayingAnimation(playing: viewModel.isPlaying, spacing: 3, cornerRadius: 2)
                                        .padding()
                                        .background(.ultraThinMaterial.opacity(0.5))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            
                            
                            
                            VStack(alignment: .leading) {
                                Text(track.title)
                                
                                Text(track.genre)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .animation(.easeOut, value: viewModel.isPlaying)
                    }
                }
            }
            .navigationTitle("Library")
            .listStyle(.inset)
        }
    }
}

#Preview {
    MusicTabView()
}
