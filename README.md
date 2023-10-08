
# MotiFy - Motivate yourself

Elevate your productivity and motivation with MotiFy. Seamlessly designed to empower your daily routine, this all-in-one app brings together three essential tools – inspiring quotes, efficient timers, and immersive Lofi music – to create a harmonious environment for achieving your goals.

## Key features

- Daily Motivational Quotes: Immerse yourself in a stream of inspiration with our thoughtfully curated daily quotes. Fuel your determination and positivity as you embark on your journey towards success.
- Smart Timer and Activities: Master your time management effortlessly. Customize tasks with preset timers that keep you focused, organized, and in control. Whether it's work, study, or personal goals, reach your full potential without losing track of time.
- Lofi Music Library: Transform your workspace with the power of music. Dive into a library of handpicked Lofi tracks, meticulously chosen to enhance your concentration, relaxation, and motivation. Create your ideal ambiance and amplify your productivity.

## Code features
- API Requests to fetch new quote every day
- Custom activities saving
- Designed and implemented custom timer
- AVKit with MPRemoteCommandCenter for full experience music player with fully written logic like queue creation/editing, autoplay, repeat options, ability to skip etc
- Fetching music library from backend servise (FirebaseFirestore)
- Artwork component for saving image to cache when fetched once
- Various custom components/extensions/managers that can be reused
- Push Notifications to notify user when time is up
  
## Screenshots

<div>
  <img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/quote.png?raw=true" alt="App Screenshot" height="350" />
  <img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/timer.png?raw=true" alt="App Screenshot" height="350" />
  <img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/music.png?raw=true" alt="App Screenshot" height="350" />
</div>

## Code snippets

```swift
/// Fetch an inspirational quote asynchronously.
/// - Returns: A `QuoteHolder` containing the fetched quote and the date it was updated.
/// - Throws: An error if the quote fetching process encounters an issue.
func fetchQuote() async throws -> QuoteHolder {
    // Headers required for the API request.
    let headers = [
        "X-RapidAPI-Key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "X-RapidAPI-Host": "quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com"
    ]
    
    // Create the API request.
    var request = URLRequest(url: URL(string: "https://quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com/quote?token=ipworld.info")!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    // Perform the API request and decode the JSON response.
    let result = try await URLSession.shared.data(for: request)
    let quote = try JSONDecoder().decode(Quote.self, from: result.0)
    
    // Create a QuoteHolder instance with the fetched quote and current date.
    let holder = QuoteHolder(dateUpdated: .now, quote: quote)
    
    return holder
}
```
### Drag to skip
  <img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/timeline.gif?raw=true" alt="App Screenshot" width="550" />
  
```swift
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

```
### Adaptive track description
<img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/description.gif?raw=true" alt="App Screenshot" width="350" />
  
```swift
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
```
### Small player design
<img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/small_player.png?raw=true" alt="App Screenshot" width="550" />
  
```swift
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
```
### Artwork reusable component
  <img src="https://github.com/stuffeddanny/MotiFy/blob/main/Screenshots/full_player.png?raw=true" alt="App Screenshot" width="350" />
  
```swift
@MainActor
final class ArtworkViewModel: ObservableObject {
    
    @Published private(set) var image: UIImage?
    
    init(with dependencies: Dependencies, for track: Track?) {
        // Check if a track is provided
        guard let track = track else { return }
        
        // Get the cache manager from dependencies
        let manager = dependencies.cacheManager
        
        // Check if the saved image exists in the cache
        if let savedImage = manager.getFrom(manager.artWorkCache, forKey: track.id) {
            self.image = savedImage
        } else {
            // If the saved image is not available, fetch it
            Task {
                if let data = try? await URLSession.shared.data(from: track.artwork).0,
                   let image = UIImage(data: data) {
                    // Add the fetched image to the cache
                    manager.addTo(manager.artWorkCache, forKey: track.id, value: image)
                    // Set the image in the ViewModel, triggering a UI update
                    self.image = image
                }
            }
        }
    }
}

struct ArtworkView: View {
    
    @ObservedObject private var viewModel: ArtworkViewModel
    
    // Initialize the view with dependencies and a track
    init(with dependencies: Dependencies, for track: Track?) {
        self.viewModel = ArtworkViewModel(with: dependencies, for: track)
    }
    
    var body: some View {
        if let image = viewModel.image {
            // Display the fetched image if available
            Image(uiImage: image)
                .resizable()
        } else {
            // Display a default placeholder image if no image is available
            Image("artwork")
                .resizable()
        }
    }
}
```
## What I've Learned

In this project I had practiced using URLRequests and APIs for artworks and quotes fetching. Using AVPlayer with MPRemoteCommandCenter I was able to create decent music player implementing all essential features. I worked with cache managing on the device for more optimized and efficient performance. Using custom models and UI components I created functioning timer which will notify user even when app is in background or closed.

## 🛠 Skills
Swift, SwiftUI, MVVM, RESTful APIs, AVPlayer, Async environment, Actors, Multithreading, WidgetKit, Combine, UserNotifications, Git, UX/UI, Webpage design
Figma, FirebaseFirestore, URLRequests

