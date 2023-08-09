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
    
    init(with dependencies: Dependencies, for track: Track) {
        let manager = dependencies.cacheManager
        
        self.image = manager.getFrom(manager.artWorkCache, forKey: track.id)
        
        Task {
            if let data = try? await URLSession.shared.data(from: track.artwork).0,
               let image = UIImage(data: data),
               self.image != image {
                
                self.image = image
                manager.addTo(manager.artWorkCache, forKey: track.id, value: image)
                
            }
        }
        
    }
}

struct ArtworkView: View {
    
    @ObservedObject private var viewModel: ArtworkViewModel
    
    init(with dependencies: Dependencies, for track: Track) {
        self.viewModel = ArtworkViewModel(with: dependencies, for: track)
    }
    
    var body: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
        } else {
            Image("artwork")
                .resizable()
        }
    }
}

#Preview {
    ArtworkView(with: .testInstance, for: .testInstance)
        .frame(width: 200, height: 200)
}
