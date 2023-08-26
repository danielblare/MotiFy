//
//  MusicTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import AVKit
import SwiftUI

struct MusicTabView: View {
    /// ViewModel for managing the Music tab's functionality.
    @StateObject private var viewModel: MusicTabViewModel
    
    /// Flag that indicates whether the full-screen player is being displayed.
    @State private var showFullScreenPlayer: Bool = false
    
    /// The track for which the description is being shown.
    @State private var trackForDescription: Track?
    
    /// A flag that tracks whether the user is currently dragging.
    @State private var isDragging: Bool = false {
        didSet {
            // Provide haptic feedback on drag state change.
            if isDragging != oldValue {
                HapticService.shared.impact(style: .light)
            }
        }
    }
    
    /// The current time in seconds during dragging.
    @State private var draggingTimeSeconds: Double = 0
    
    /// The width of the drag timeline.
    @State private var dragTimelineWidth: CGFloat = .zero
    
    /// A flag indicating whether the queue is being displayed.
    @State private var showQueue: Bool = false
    
    /// The dependencies required for initialization.
    private let dependencies: Dependencies
    
    /// Initializes the MusicTabView with the provided dependencies.
    /// - Parameter dependencies: The dependencies required for the view.
    init(with dependencies: Dependencies) {
        // Initialize the StateObject viewModel.
        self._viewModel = .init(wrappedValue: MusicTabViewModel(with: dependencies))
        self.dependencies = dependencies
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    // Display tracks in a sorted order.
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
                        // Button to show track description when tapped.
                        Button {
                            trackForDescription = track
                        } label: {
                            // Display a TrackRow for each track.
                            TrackRow(for: track)
                                .frame(height: 60)
                        }
                        // Leading swipe actions.
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            // Button to add the track to the start of the queue.
                            Button {
                                HapticService.shared.impact(style: .medium)
                                viewModel.addToStart(QueueElement(track: track))
                            } label: {
                                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            }
                            .tint(.indigo)
                            
                            // Button to add the track to the end of the queue.
                            Button {
                                HapticService.shared.impact(style: .medium)
                                viewModel.addToEnd(QueueElement(track: track))
                            } label: {
                                Image(systemName: "text.line.last.and.arrowtriangle.forward")
                            }
                            .tint(.orange)
                        }
                        // Trailing swipe actions.
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            let isFavorite = viewModel.isFavorite(track)
                            
                            // Button to toggle favorite status.
                            Button {
                                HapticService.shared.impact(style: .medium)
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
                
                .listStyle(.inset)
                
                if let track = viewModel.trackPlaying {
                    SmallPlayer(for: track)
                        .animation(.interactiveSpring, value: viewModel.trackPlaying)
                }
            }
            .navigationTitle("Library")
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
                    .animation(.interactiveSpring, value: viewModel.queue)
            }
            .sheet(isPresented: $showQueue) {
                NavigationStack {
                    Group {
                        // Display the queue list if it's not empty.
                        if !viewModel.queue.isEmpty {
                            List {
                                // Iterate through each element in the queue.
                                ForEach(viewModel.queue) { element in
                                    // Display a track row for each element.
                                    TrackRow(for: element.track, isAnimatedWhenPlaying: false)
                                        .frame(height: 50)
                                }
                                .onDelete { indexSet in
                                    // Allow deleting items from the queue.
                                    viewModel.deleteFromQueue(on: indexSet)
                                }
                                .onMove { indexSet, index in
                                    // Enable moving items within the queue.
                                    viewModel.moveElementInQueue(from: indexSet, to: index)
                                }
                            }
                            .listStyle(.inset)
                        } else {
                            // Display a message if the queue is empty.
                            Text("No tracks in queue")
                                .foregroundStyle(.secondary)
                                .font(.title)
                        }
                    }
                    .navigationTitle("Queue")
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            // Button to clear the entire queue.
                            Button("Clear") {
                                viewModel.clearQueue()
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            // Standard Edit button for list editing.
                            EditButton()
                        }
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
    
    /// Generates a view presenting the description of a track.
    /// - Parameter track: The track for which the description is being shown.
    /// - Returns: A view displaying the track's description and related information.
    private func Description(for track: Track) -> some View {
        GeometryReader { proxy in
            ScrollView {
                // Display the artwork of the track.
                ArtworkView(with: dependencies, for: track)
                    .scaledToFill()
                    .frame(maxHeight: proxy.size.height * 0.4, alignment: .top)
                    .clipped()
                // Display the duration overlay at the bottom.
                    .overlay(alignment: .bottomTrailing) {
                        Text(formattedDuration(seconds: Int(track.duration.seconds), format: .full))
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding()
                    }
                // Display the favorite icon at the top.
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
                            // Display the track title with a line limit.
                            Text(track.title)
                                .lineLimit(2)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // Display the track author with a line limit.
                            Text(track.author)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Button to play the track.
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
                    
                    // Display the "Description" label.
                    Text("Description:")
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    
                    // Display the track's description.
                    Text(track.description)
                }
                .padding()
            }
            // Hide scroll indicators and content background.
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background {
                // Display a blurred version of the artwork as the background.
                ArtworkView(with: dependencies, for: track)
                    .scaledToFill()
                    .blur(radius: 200)
                    .ignoresSafeArea()
            }
        }
    }
    
    /// Generates a view for the full-screen player.
    /// - Parameter track: The track being played in the full-screen player.
    /// - Returns: A view presenting track information and player controls.
    private func FullScreenPlayer(for track: Track?) -> some View {
        VStack {
            // Display the artwork of the track.
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    // Display a favorite icon if the track is a favorite.
                    if let track, viewModel.isFavorite(track) {
                        Image(systemName: "star.fill")
                            .symbolRenderingMode(.multicolor)
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding()
                    }
                }
                .frame(height: 300)
                .padding()
            
            VStack {
                // Display the track title.
                Text(track?.title ?? "-")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                // Display the track author.
                Text(track?.author ?? "-")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.title3)
            }
            .lineLimit(1)
            .padding(.horizontal)
            
            VStack {
                // Display the timeline for dragging and seeking.
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.5))
                    
                    if let track {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(isDragging ? .white : .white.opacity(0.8))
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
                
                // Display the current time and remaining time.
                let timeline = getTimeline(for: track)
                HStack {
                    Text(timeline.current)
                    Spacer(minLength: 0)
                    Text(timeline.left)
                }
                .monospacedDigit()
                .foregroundStyle(isDragging ? .white : .white.opacity(0.5))
                .fontWeight(isDragging ? .semibold : .regular)
                .font(.footnote)
                .padding(.horizontal, 5)
                
            }
            .frame(minHeight: 40)
            .padding()
            .scaleEffect(isDragging ? 1.03 : 1)
            .animation(.snappy(duration: 0.3), value: isDragging)
            
            // Playback controls.
            HStack {
                // Toggle Autoplay button.
                Button {
                    HapticService.shared.impact(style: .light)
                    viewModel.toggleAutoplay()
                } label: {
                    ZStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                            .rotationEffect(.degrees(viewModel.autoplay ? 270 : 90))
                        
                        Image(systemName: "play.fill")
                            .font(.caption2)
                    }
                    .foregroundStyle(viewModel.autoplay ? Color.accentColor : .white.opacity(0.5))
                }
                .animation(.bouncy, value: viewModel.autoplay)
                
                Spacer()
                
                Group {
                    // Previous track button.
                    Button {
                        HapticService.shared.impact(style: .light)
                        try? viewModel.prev()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                    }
                    
                    // Play/pause button.
                    Button {
                        if let track {
                            HapticService.shared.impact(style: .light)
                            viewModel.isPlaying ? viewModel.pause() : viewModel.play(track)
                        }
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                    }
                    .padding(.horizontal)
                    
                    // Next track button.
                    Button {
                        HapticService.shared.impact(style: .light)
                        try? viewModel.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                    }
                }
                .foregroundStyle(.white)
                
                Spacer()
                
                // Toggle repeat option button.
                Button {
                    HapticService.shared.impact(style: .light)
                    viewModel.nextRepeatOption()
                } label: {
                    viewModel.repeatOption.icon
                        .font(.title2)
                        .foregroundStyle(viewModel.repeatOption == .dontRepeat ? .white.opacity(0.5) : .accent)
                }
            }
            .padding(.horizontal)
            .disabled(track == nil)
            
            Spacer()
            
            // Display the next track or autoplay indicator.
            if let nextElement = viewModel.queue.first {
                Group {
                    Text(nextElement.autoplay ? "Autoplay:" : "Next in queue:")
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TrackRow(for: nextElement.track, isAnimatedWhenPlaying: false)
                        .padding(.horizontal)
                        .frame(height: 50)
                }
                .foregroundStyle(.white)
            }
        }
        .padding()
        .background {
            // Display a blurred version of the artwork as the background.
            ArtworkView(with: dependencies, for: track)
                .scaledToFill()
                .blur(radius: 100)
                .ignoresSafeArea()
        }
    }
    
    /// Computes the timeline information for the current track.
    /// - Parameter track: The track for which the timeline is being calculated.
    /// - Returns: A tuple containing formatted current time and remaining time.
    private func getTimeline(for track: Track?) -> (current: String, left: String) {
        if let track {
            // Calculate total hours based on track duration.
            let totalHours = Int(track.duration.seconds) / 3600
            // Choose format based on whether the track's duration is more than an hour.
            let format: Format = totalHours >= 1 ? .hours : .minutes
            
            // Calculate total seconds of current time, considering dragging if in progress.
            let totalCurrentSeconds = Int(isDragging ? draggingTimeSeconds : viewModel.currentTime.seconds)
            
            // Calculate total seconds left in the track.
            let totalSecondsLeft = Int(track.duration.seconds) - totalCurrentSeconds
            
            // Return formatted current time and remaining time.
            return (formattedDuration(seconds: totalCurrentSeconds, format: format), "-" + formattedDuration(seconds: totalSecondsLeft, format: format))
        } else {
            // Return placeholder values if track is not available.
            return ("--:--", "--:--")
        }
    }
    
    /// Generates a small player view for a given track.
    /// - Parameter track: The track for which the small player is being displayed.
    /// - Returns: A view presenting track information and playback controls.
    private func SmallPlayer(for track: Track) -> some View {
        HStack {
            // Display the artwork of the track.
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                // Display the track title.
                Text(track.title)
                
                // Display the track author with secondary style.
                Text(track.author)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer(minLength: 0)
            
            HStack {
                // Button to play the previous track.
                Button {
                    try? viewModel.prev()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.body)
                }
                
                // Button to play/pause the current track.
                Button {
                    viewModel.isPlaying ? viewModel.pause() : viewModel.play(track)
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                // Button to play the next track.
                Button {
                    try? viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.body)
                }
            }
            .foregroundStyle(.primary)
            .padding(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding()
        // Make the background clear but tappable.
        .background {
            Color.clearButTappable
        }
        // Display the blurred artwork as the background.
        .background {
            ArtworkView(with: dependencies, for: track)
                .scaledToFill()
                .blur(radius: 150)
                .allowsHitTesting(false)
        }
        // Display the playback progress indicator.
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.3))
                
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: proxy.size.width / (track.duration.seconds / viewModel.currentTime.seconds))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 4)
        }
        // Clip the view with rounded corners.
        .clipShape(RoundedRectangle(cornerRadius: 10))
        // Show full-screen player when tapped.
        .onTapGesture {
            showFullScreenPlayer = true
        }
    }
    
    /// Generates a view representing a track in a list.
    /// - Parameters:
    ///   - track: The track to be displayed in the row.
    ///   - isAnimatedWhenPlaying: Determines whether to show playing animation when the track is playing.
    /// - Returns: A view presenting track information with optional playing animation.
    private func TrackRow(for track: Track, isAnimatedWhenPlaying: Bool = true) -> some View {
        HStack {
            // Display the artwork of the track.
            ArtworkView(with: dependencies, for: track)
                .scaledToFit()
                .overlay {
                    // Show playing animation if the track is currently playing and animation is enabled.
                    if isAnimatedWhenPlaying, viewModel.trackPlaying?.id == track.id {
                        MusicPlayingAnimation(playing: viewModel.isPlaying, spacing: 3, cornerRadius: 2)
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.5))
                            .foregroundStyle(.gray)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading) {
                // Display the track title.
                Text(track.title)
                
                // Display the track author with secondary style.
                Text(track.author)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer()
            
            // Display a favorite icon if the track is a favorite.
            if viewModel.isFavorite(track) {
                Image(systemName: "star.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        // Apply animation when the playing state changes.
        .animation(.easeOut, value: viewModel.isPlaying)
    }
    
    /// Enumeration to specify different time format options.
    private enum Format {
        case hours
        case minutes
        case full
        
        /// Provides the string format corresponding to the time format option.
        var stringFormat: String {
            switch self {
            case .hours:
                return "%01d:%02d:%02d"
            case .minutes:
                return "%01d:%02d"
            case .full:
                return "%02d:%02d:%02d"
            }
        }
    }
    
    /// Formats a given duration in seconds into a human-readable time format.
    /// - Parameters:
    ///   - seconds: The duration in seconds.
    ///   - format: The time format option to use for formatting.
    /// - Returns: A formatted string representing the duration.
    private func formattedDuration(seconds: Int, format: Format) -> String {
        // Calculate hours, minutes, and remaining seconds.
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let seconds = seconds % 60
        
        // Prepare the arguments for formatting.
        var arguments: [CVarArg] = [minutes, seconds]
        if format == .hours || format == .full {
            arguments.insert(hours, at: 0)
        }
        
        // Format the duration using the specified string format.
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
