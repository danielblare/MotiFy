//
//  Track.swift
//  MotiFy
//
//  Created by Daniel on 8/10/23.
//

import Foundation
import AVKit

struct FirestoreTrackModel: Codable {
    let id: String
    let title: String
    let genre: String
    let audio: String
    let artwork: String
    let description: String
    
    static let testInstance = FirestoreTrackModel(id: "yKjoNS0o5YkgFSIADjPF", title: "Test Title", genre: "Test genge", audio: "https://download.xn--41a.wiki/cache/2/3db/526816593_456239896.mp3?filename=Yeat-G%C3%ABt%20Busy.mp3", artwork: "https://www.udiscovermusic.com/wp-content/uploads/2022/04/2-Alive-Geek-Pack_-Explicit-Cover-2.jpg", description: "Test description")
}

struct Track: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let genre: String
    let audio: URL
    let artwork: URL
    let description: String
    let duration: CMTime
    
    init(id: String, title: String, genre: String, audio: URL, artwork: URL, description: String, duration: CMTime) {
        self.id = id
        self.title = title
        self.genre = genre
        self.audio = audio
        self.artwork = artwork
        self.description = description
        self.duration = duration
    }
    
    init(from model: FirestoreTrackModel, storageManager manager: StorageManager) async throws {
        let audioURL = try await manager.get(from: model.audio)
        let artworkURL = try await manager.get(from: model.artwork)
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = audioURL
        self.artwork = artworkURL
        self.duration = try await AVURLAsset(url: audioURL).load(.duration)
    }
    
    init(from model: FirestoreTrackModel) async throws {
        guard let audioURL = URL(string: model.audio),
              let artworkURL = URL(string: model.artwork) else { throw URLError(.badURL) }
        self.id = model.id
        self.title = model.title
        self.genre = model.genre
        self.description = model.description
        self.audio = audioURL
        self.artwork = artworkURL
        self.duration = try await AVURLAsset(url: audioURL).load(.duration)
    }
    
    static let offlineInstance = Track(id: "DHA4WlsFJMJCfCK1DTu3", title: "Money so big", genre: "Hip-hop", audio: URL(string: "https://youtu.be/T_ASKLftsLs")!, artwork: URL(string: "https://www.udiscovermusic.com/wp-content/uploads/2022/04/2-Alive-Geek-Pack_-Explicit-Cover-2.jpg")!, description: "Immerse yourself in a sonic cocoon of tranquility with our carefully curated selection of Lo-Fi music, expertly crafted to enhance your study sessions. Designed to be both captivating and unobtrusive, our Lo-Fi playlist is the ideal companion for your academic pursuits.\n\nAs you delve into your studies, the gentle ebb and flow of Lo-Fi beats will transport you to a realm of focused concentration. The soothing melodies and understated rhythms create an ambiance that effortlessly melds with your surroundings, fostering a sense of calm productivity.\n\nThe tapestry of Lo-Fi melodies is woven with warmth and nostalgia, yet remains contemporary in its composition. Subtle crackles and imperfections in the audio offer a touch of authenticity, reminiscent of vintage vinyl records. These delightful imperfections add to the allure, inviting you to embrace the present moment while your mind remains steadfast on your scholarly endeavors.\n\nWhether you're tackling complex equations, diving into literature, or researching vast realms of knowledge, our Lo-Fi music provides a backdrop that nurtures your cognitive faculties. The unobtrusive nature of the music allows your thoughts to flow freely, unburdened by distractions.\n\nAllow the atmospheric soundscape to guide you through your study sessions, enhancing your focus, concentration, and retention. Each note is a stepping stone towards your academic goals, creating an environment where learning becomes an invigorating journey.\n\nElevate your study experience with our meticulously curated Lo-Fi music, where the harmonious marriage of melody and ambiance paves the way for a fruitful and enriching scholarly adventure. Discover the harmonious intersection of auditory delight and academic prowess as you indulge in the world of Lo-Fi music for studying.", duration: CMTime(seconds: 60 * 59, preferredTimescale: 600))
}
