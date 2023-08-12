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
        guard let track else { return }
        let manager = dependencies.cacheManager
        
        if let savedImage = manager.getFrom(manager.artWorkCache, forKey: track.id) {
            self.image = savedImage
        } else {
            Task {
                if let data = try? await URLSession.shared.data(from: track.artwork).0,
                   let image = UIImage(data: data) {
                    manager.addTo(manager.artWorkCache, forKey: track.id, value: image)
                    self.image = image
                }
            }
        }
    }
}

struct ArtworkView: View {
    
    @ObservedObject private var viewModel: ArtworkViewModel
    
    init(with dependencies: Dependencies, for track: Track?) {
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
    ArtworkView(with: .testInstance, for: .offlineInstance)
        .frame(width: 200, height: 200)
}
