//
//  MusicTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import AVKit
import SwiftUI

struct MusicTabView: View {
    @StateObject private var viewModel = MusicTabViewModel()
    @State private var showSheet: Bool = true
    
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
                            .lineLimit(1)
                        }
                        .animation(.easeOut, value: viewModel.isPlaying)
                    }
                }
            }
            .navigationTitle("Library")
            .listStyle(.inset)
            .overlay(alignment: .bottom) {

                if let trackID = viewModel.trackPlaying, let track = viewModel.getTrack(by: trackID) {
                    HStack {
                        
                        AsyncImage(url: track.artwork) { image in
                            image
                                .resizable()
                        } placeholder: {
                            Image("artwork")
                                .resizable()
                        }
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
                                viewModel.isPlaying ? viewModel.pause() : viewModel.play()
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
                        .animation(.bouncy, value: viewModel.isPlaying)
                    }
                    
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(alignment: .top) {
                            //                            ZStack(alignment: .top) {
                            //                                Rectangle()
                            //                                    .fill(.secondary.opacity(0.3))
                            //                                    .frame(height: 4)
                            //
                            //                                HStack(alignment: .top, spacing: 0) {
                            //                                    Rectangle()
                            //                                        .fill(.secondary)
                            //                                        .frame(height: 4)
                            //
                            //                                    UnevenRoundedRectangle(bottomLeadingRadius: 1, bottomTrailingRadius: 1)
                            //                                        .frame(width: 3, height: 7)
                            //
                            //                                }
                            //                                .frame(width: proxy.size.width / (track.duration.seconds / viewModel.currentTime.seconds))
                            //                                    .frame(maxWidth: .infinity, alignment: .leading)
                            //                            }
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
                if let trackID = viewModel.trackPlaying, let track = viewModel.getTrack(by: trackID) {
                    VStack {
                        AsyncImage(url: track.artwork) { image in
                            image
                                .resizable()
                        } placeholder: {
                            Image("artwork")
                                .resizable()
                        }
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

                            let totalCurrentSeconds = Int(viewModel.currentTime.seconds)
                            let currentMinutes = totalCurrentSeconds / 60
                            let currentSeconds = totalCurrentSeconds % 60
                            
                            let totalSecondsLeft = Int(track.duration.seconds) - totalCurrentSeconds
                            let minutesLeft = totalSecondsLeft / 60
                            let secondsLeft = totalSecondsLeft % 60

                            HStack {
                                Text(String(format: "%01d:%02d", currentMinutes, currentSeconds))
                                
                                Spacer(minLength: 0)
                                
                                Text(String(format: "-%01d:%02d", minutesLeft, secondsLeft))
                            }
                            .foregroundStyle(.secondary)
                            .font(.footnote)

                        }
                        .padding()
                        
                        
                        
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }

            }
        }
    }
}

#Preview {
    TabView {
        MusicTabView()
            .tabItem {
                Image(systemName: "note")
            }
    }
}
