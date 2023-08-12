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
    
    @State private var showQueue: Bool = false
    
    private let dependencies: Dependencies
    
    init(with dependencies: Dependencies) {
        self._viewModel = .init(wrappedValue: MusicTabViewModel(with: dependencies))
        self.dependencies = dependencies
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tracks.sorted(by: { $0.title < $1.title }).sorted(by: { track1, track2 in
                    if viewModel.isFavorite(track1), viewModel.isFavorite(track2),
                       let index1 = viewModel.favorites.firstIndex(of: track1.id),
                       let index2 = viewModel.favorites.firstIndex(of: track2.id) {
                        return index1 < index2
                    } else if viewModel.isFavorite(track1) {
                        return true
                    } else {
                        return false
                    }
                })) { track in
                    Button {
                        trackForDescription = track
                    } label: {
                        TrackRow(for: track)
                            .frame(height: 60)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.addToStart(track)
                        } label: {
                            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        }
                        .tint(.indigo)
                        
                        Button {
                            viewModel.addToEnd(track)
                        } label: {
                            Image(systemName: "text.line.last.and.arrowtriangle.forward")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        let isFavorite = viewModel.isFavorite(track)
                        Button {
                            withAnimation {
                                viewModel.setFavorite(to: !isFavorite, for: track)
                            }
                        } label: {
                            Image(systemName: isFavorite ? "star.slash" : "star")
                                .symbolVariant(.fill)
                        }
                        .tint(.yellow)
                    }
                }
            }
            .navigationTitle("Library")
            .listStyle(.inset)
            .overlay(alignment: .bottom) {
                if let track = viewModel.trackPlaying {
                    SmallPlayer(for: track)
                        .animation(.interactiveSpring, value: viewModel.trackPlaying)
                }
            }
            .sheet(item: $trackForDescription) { track in
                Description(for: track)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showFullScreenPlayer) {
                FullScreenPlayer(for: viewModel.trackPlaying)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .animation(.interactiveSpring, value: viewModel.trackPlaying)
            }
            .sheet(isPresented: $showQueue) {
                NavigationStack {
                    Group {
                        if !viewModel.queue.isEmpty {
                            List {
                                ForEach(viewModel.queue) { track in
                                    TrackRow(for: track, isAnimatedWhenPlaying: false)
                                }
                                .onDelete { indexSet in
                                    viewModel.deleteFromQueue(on: indexSet)
                                }
                                .onMove { indexSet, index in
                                    viewModel.moveElementInQueue(from: indexSet, to: index)
                                }
                            }
                            .listStyle(.inset)
                        } else {
                            Text("No tracks in queue")
                                .foregroundStyle(.secondary)
                                .font(.title)
                        }
                    }
                    .navigationTitle("Queue")
                    .toolbar {
                        EditButton()
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showQueue.toggle()
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
        }
    }
    
    private func Description(for track: Track) -> some View {
        GeometryReader { proxy in
            ScrollView {
                ArtworkView(with: dependencies, for: track)
                    .scaledToFill()
                    .frame(height: proxy.size.height * 0.4, alignment: .top)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) {
                        Text(formattedDuration(seconds: Int(track.duration.seconds), format: .full))
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding()
                    }
                    .overlay(alignment: .topTrailing) {
                        if viewModel.isFavorite(track) {
                            Image(systemName: "star.fill")
                                .symbolRenderingMode(.multicolor)
                                .padding(5)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding()
                        }
                    }
                
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
            .scrollContentBackground(.hidden)
            .background {
                ArtworkView(with: dependencies, for: track)
                    .scaledToFill()
                    .blur(radius: 200)
                    .ignoresSafeArea()
            }
            
        }
    }
    
    private func FullScreenPlayer(for track: Track?) -> some View {
        VStack {
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    if let track, viewModel.isFavorite(track) {
                        Image(systemName: "star.fill")
                            .symbolRenderingMode(.multicolor)
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding()
                    }
                }
                .padding()
            
            VStack {
                Text(track?.title ?? "-")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(track?.genre ?? "-")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .lineLimit(1)
            .padding(.horizontal)
            
            VStack {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                    
                    if let track {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(isDragging ? .primary : .secondary)
                                .frame(width: proxy.size.width / (track.duration.seconds / (isDragging ? draggingTimeSeconds : viewModel.currentTime.seconds)))
                                .onChange(of: proxy.size) { newSize in
                                    dragTimelineWidth = newSize.width
                                }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(height: isDragging ? 15 : 5)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let track else { return }
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
                
                let timeline = getTimeline(for: track)
                
                HStack {
                    Text(timeline.current)
                    
                    Spacer(minLength: 0)
                    
                    Text(timeline.left)
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
                
                Image(systemName: "person")

                Spacer()

                Button {
                    viewModel.prev()
                } label: {
                    Image(systemName: "backward.fill")
                        .foregroundStyle(Color.primary)
                        .imageScale(.large)
                }
                
                Button {
                    if let track {
                        viewModel.isPlaying ? viewModel.pause() : viewModel.play(track)
                    }
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
                
                Spacer()
                
                Button {
                    viewModel.nextRepeatOption()
                } label: {
                    viewModel.repeatOption.icon
                        .foregroundStyle(viewModel.repeatOption == .dontRepeat ? Color.secondary : .accent)
                }
                
            }
            .padding(.horizontal)
            .disabled(track == nil)
            
            Spacer(minLength: 0)
            
            if let nextTrack = viewModel.queue.first {
                    Text("Next in queue:")
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TrackRow(for: nextTrack, isAnimatedWhenPlaying: false)
                    .padding(.horizontal)
                    .frame(height: 50)

            }
        }
        .padding()
        .background {
            ArtworkView(with: dependencies, for: track)
                .scaledToFill()
                .blur(radius: 100)
                .ignoresSafeArea()
        }
    }
    
    private func getTimeline(for track: Track?) -> (current: String, left: String) {
        if let track {
            let totalHours = Int(track.duration.seconds) / 3600
            let format: Format = totalHours >= 1 ? .hours : .minutes
            
            let totalCurrentSeconds = Int(isDragging ? draggingTimeSeconds : viewModel.currentTime.seconds)
            
            let totalSecondsLeft = Int(track.duration.seconds) - totalCurrentSeconds
            
            return (formattedDuration(seconds: totalCurrentSeconds, format: format), "-" + formattedDuration(seconds: totalSecondsLeft, format: format))
        } else {
            return ("--:--", "--:--")
        }
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
        .background {
            ArtworkView(with: dependencies, for: track)
                .scaledToFill()
                .blur(radius: 200)
                .ignoresSafeArea()
        }
        
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
    
    private func TrackRow(for track: Track, isAnimatedWhenPlaying: Bool = true) -> some View {
        HStack {
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .overlay {
                    if isAnimatedWhenPlaying, viewModel.trackPlaying?.id == track.id {
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
            
            Spacer()
            
            if viewModel.isFavorite(track) {
                Image(systemName: "star.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        .animation(.easeOut, value: viewModel.isPlaying)
    }
    
    private enum Format {
        case hours
        case minutes
        case full
        
        var stringFormat: String {
            switch self {
            case .hours:
                "%01d:%02d:%02d"
            case .minutes:
                "%01d:%02d"
            case .full:
                "%02d:%02d:%02d"
            }
        }
    }
    
    private func formattedDuration(seconds: Int, format: Format) -> String {
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let seconds = seconds % 60
        
        var arguments: [CVarArg] = [minutes, seconds]
        if format == .hours || format == .full {
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
