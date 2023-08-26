//
//  ArtworkView.swift
//  MotiFy
//
//  Created by Daniel on 8/9/23.
//

import SwiftUI

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

#Preview {
    ArtworkView(with: .testInstance, for: .offlineInstance)
        .frame(width: 200, height: 200)
}
