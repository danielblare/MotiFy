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
    @State private var showSheet: Bool = true
    
    private let dependencies: Dependencies
    
    init(with dependencies: Dependencies) {
        self._viewModel = .init(wrappedValue: MusicTabViewModel(with: dependencies))
        self.dependencies = dependencies
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tracks) { track in
                    Button {
                        if viewModel.trackPlaying?.id == track.id, viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            viewModel.play(track)
                        }
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
            }
            .navigationTitle("Library")
            .listStyle(.inset)
            .overlay(alignment: .bottom) {
                
                if let track = viewModel.trackPlaying {
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
                                
                            } label: {
                                Image(systemName: "backward.end.fill")
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
                                
                            } label: {
                                Image(systemName: "forward.end.fill")
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
                        .animation(.linear, value: viewModel.currentTime)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        showSheet = true
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                if let track = viewModel.trackPlaying {
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
                                        .fill(.secondary)
                                        .frame(width: proxy.size.width / (track.duration.seconds / viewModel.currentTime.seconds))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .frame(height: 5)
                            .animation(.linear, value: viewModel.currentTime)
                            
                            let totalHours = Int(track.duration.seconds) / 3600
                            let format: Format = totalHours >= 1 ? .hours : .minutes
                            
                            let totalCurrentSeconds = Int(viewModel.currentTime.seconds)
                            
                            let totalSecondsLeft = Int(track.duration.seconds) - totalCurrentSeconds
                            
                            HStack {
                                Text(formattedDuration(seconds: totalCurrentSeconds, format: format))
                                
                                Spacer(minLength: 0)
                                
                                Text("-" + formattedDuration(seconds: totalSecondsLeft, format: format))
                            }
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .padding(.horizontal, 5)
                            
                        }
                        .padding()
                        
                        HStack {
                            Button {
                                
                            } label: {
                                Image(systemName: "backward.end.fill")
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
                                
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .foregroundStyle(Color.primary)
                                    .imageScale(.large)
                            }
                            
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
                
            }
        }
    }
    
    enum Format {
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
    
    func formattedDuration(seconds: Int, format: Format) -> String {
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
