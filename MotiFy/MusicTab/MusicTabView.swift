//
//  MusicTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import AVKit
import SwiftUI

struct MusicTabView: View {
    @StateObject private var viewModel: MusicTabViewModel
    @State private var showFullScreenPlayer: Bool = true
    @State private var trackForDescription: Track?
    
    @State private var isDragging: Bool = false {
        didSet {
            if isDragging != oldValue {
                HapticService.shared.impact(style: .light)
            }
        }
    }
    @State private var draggingTimeSeconds: Double = 0
    @State private var dragTimelineWidth: CGFloat = .zero
    
    private let dependencies: Dependencies
    
    init(with dependencies: Dependencies) {
        self._viewModel = .init(wrappedValue: MusicTabViewModel(with: dependencies))
        self.dependencies = dependencies
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tracks) {
                    TrackRow(for: $0)
                }
            }
            .navigationTitle("Library")
            .listStyle(.inset)
            .overlay(alignment: .bottom) {
                if let track = viewModel.trackPlaying {
                    SmallPlayer(for: track)
                }
            }
            .sheet(item: $trackForDescription) { track in
                Description(for: track)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showFullScreenPlayer) {
                if let track = viewModel.trackPlaying {
                    FullScreenPlayer(for: track)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                
            }
        }
    }
    
    private func Description(for track: Track) -> some View {
        GeometryReader { proxy in
            ScrollView {
                ArtworkView(with: dependencies, for: track)
                    .scaledToFill()
                    .frame(height: proxy.size.height * 0.4)
                    .clipped()
                
                VStack(alignment: .leading) {
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            Text(track.genre)
                                .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            viewModel.play(track)
                            trackForDescription = nil
                        } label: {
                            let accent: Color = .accentColor
                            HStack {
                                Text("Play")
                                    .fontWeight(.bold)
                                    .font(.title3)
                                Image(systemName: "play.fill")
                            }
                            .foregroundStyle(accent.contrastingTextColor())
                            .padding(10)
                            .background(accent)
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text("Description:")
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    
                    Text(track.description)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private func FullScreenPlayer(for track: Track) -> some View {
        VStack {
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
            
            VStack {
                Text(track.title)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(track.genre)
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .lineLimit(1)
            .padding(.horizontal)
            
            VStack {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                    
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(isDragging ? .primary : .secondary)
                            .frame(width: proxy.size.width / (track.duration.seconds / (isDragging ? draggingTimeSeconds : viewModel.currentTime.seconds)))
                            .onChange(of: proxy.size) { newSize in
                                dragTimelineWidth = newSize.width
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(height: isDragging ? 15 : 5)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        draggingTimeSeconds = viewModel.currentTime.seconds
                        
                        isDragging = true
                        
                        // Settings
                        let lineLength: CGFloat = dragTimelineWidth
                        let trackDuration = track.duration.seconds
                        let factor: Double = 1
                        
                        // Calculations
                        let distancePerSecond = lineLength / trackDuration
                        
                        let changeInSeconds = value.translation.width * factor / distancePerSecond
                        
                        let newDraggingTime = draggingTimeSeconds + changeInSeconds
                        draggingTimeSeconds = min(max(newDraggingTime, 0), trackDuration)
                        
                    }
                    .onEnded { value in
                        let newTime: CMTime = .init(seconds: draggingTimeSeconds, preferredTimescale: 600)
                        
                        Task {
                            await viewModel.skipTo(newTime)
                            
                            isDragging = false
                        }
                    }
                )
                
                
                let totalHours = Int(track.duration.seconds) / 3600
                let format: Format = totalHours >= 1 ? .hours : .minutes
                
                let totalCurrentSeconds = Int(isDragging ? draggingTimeSeconds : viewModel.currentTime.seconds)
                
                let totalSecondsLeft = Int(track.duration.seconds) - totalCurrentSeconds
                
                HStack {
                    Text(formattedDuration(seconds: totalCurrentSeconds, format: format))
                    
                    Spacer(minLength: 0)
                    
                    Text("-" + formattedDuration(seconds: totalSecondsLeft, format: format))
                }
                .monospacedDigit()
                .foregroundStyle(isDragging ? .primary : .secondary)
                .font(.footnote)
                .padding(.horizontal, 5)
                
            }
            .frame(minHeight: 40)
            .padding()
            .scaleEffect(isDragging ? 1.03 : 1)
            .animation(.snappy(), value: isDragging)
            
            HStack {
                Button {
                    viewModel.prev()
                } label: {
                    Image(systemName: "backward.fill")
                        .foregroundStyle(Color.primary)
                        .imageScale(.large)
                }
                
                Button {
                    viewModel.isPlaying ? viewModel.pause() : viewModel.play(track)
                } label: {
                    let color: Color = .accentColor
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(color)
                        
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .foregroundStyle(color.contrastingTextColor())
                            .padding(20)
                            .padding(.leading, viewModel.isPlaying ? 0 : 5)
                    }
                    .frame(width: 70, height: 70)
                }
                .padding(.horizontal)
                
                Button {
                    viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(Color.primary)
                        .imageScale(.large)
                }
                
            }
            
            Spacer(minLength: 0)
            
        }
        .padding()
    }
    
    private func SmallPlayer(for track: Track) -> some View {
        HStack {
            
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            
            VStack(alignment: .leading) {
                Text(track.title)
                
                Text(track.genre)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer(minLength: 0)
            
            HStack {
                Button {
                    viewModel.prev()
                } label: {
                    Image(systemName: "backward.fill")
                        .foregroundStyle(Color.primary)
                }
                
                Button {
                    viewModel.isPlaying ? viewModel.pause() : viewModel.play(track)
                } label: {
                    let color: Color = .accentColor
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(color)
                        
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(color.contrastingTextColor())
                            .padding([.leading, .bottom], viewModel.isPlaying ? 0 : 1)
                    }
                    .frame(width: 40, height: 40, alignment: .center)
                }
                
                Button {
                    viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .foregroundStyle(Color.primary)
                }
                
            }
            .padding(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                
                GeometryReader { proxy in
                    
                    Rectangle()
                        .fill(.secondary)
                    
                        .frame(width: proxy.size.width / (track.duration.seconds / viewModel.currentTime.seconds))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            showFullScreenPlayer = true
        }
    }
    
    private func TrackRow(for track: Track) -> some View {
        Button {
            trackForDescription = track
        } label: {
            HStack {
                
                ArtworkView(with: dependencies, for: track)
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .overlay {
                        if viewModel.trackPlaying?.id == track.id {
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
                .lineLimit(1)
            }
            .animation(.easeOut, value: viewModel.isPlaying)
        }
    }
    
    private enum Format {
        case hours
        case minutes
        
        var stringFormat: String {
            switch self {
            case .hours:
                "%01d:%02d:%02d"
            case .minutes:
                "%01d:%02d"
            }
        }
    }
    
    private func formattedDuration(seconds: Int, format: Format) -> String {
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let seconds = seconds % 60
        
        var arguments: [CVarArg] = [minutes, seconds]
        if format == .hours {
            arguments.insert(hours, at: 0)
        }
        
        return String(format: format.stringFormat, arguments: arguments)
        
    }
}

#Preview {
    TabView {
        MusicTabView(with: .testInstance)
            .tabItem {
                Image(systemName: "note")
            }
    }
}
