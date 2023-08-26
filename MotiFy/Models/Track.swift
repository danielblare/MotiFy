//
//  Track.swift
//  MotiFy
//
//  Created by Daniel on 8/10/23.
//

import Foundation
import AVKit

struct FirestoreTrackModel: Codable {
    let id: String // Unique identifier for the track
    let title: String // Title of the track
    let author: String // Author of the track
    let audio: String // URL string for the audio file
    let artwork: String // URL string for the artwork image
    let description: String // Description of the track
    
    enum CodingKeys: CodingKey {
        case id
        case title
        case author
        case audio
        case artwork
        case description
    }
    
    // Initializer to create a FirestoreTrackModel instance
    init(id: String, title: String, author: String, audio: String, artwork: String, description: String) {
        self.id = id
        self.title = title
        self.author = author
        self.audio = audio
        self.artwork = artwork
        self.description = description
    }
    // Test instance for FirestoreTrackModel
    static let testInstance = FirestoreTrackModel(id: "yKjoNS0o5YkgFSIADjPF", title: "Test Title", author: "Test author", audio: "https://download.xn--41a.wiki/cache/2/3db/526816593_456239896.mp3?filename=Yeat-G%C3%ABt%20Busy.mp3", artwork: "https://www.udiscovermusic.com/wp-content/uploads/2022/04/2-Alive-Geek-Pack_-Explicit-Cover-2.jpg", description: "Test description")
    
    // Initializer to decode from a Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.audio = try container.decode(String.self, forKey: .audio)
        self.artwork = try container.decode(String.self, forKey: .artwork)
        self.description = try container.decode(String.self, forKey: .description).replacingOccurrences(of: "%p", with: "\n")
    }
}

struct Track: Codable, Identifiable, Equatable, Hashable {
    let id: String // Unique identifier for the track
    let title: String // Title of the track
    let author: String // Author of the track
    let audio: URL // URL for the audio file
    let artwork: URL // URL for the artwork image
    let description: String // Description of the track
    let duration: CMTime // Duration of the track
    
    // Initializer to create a Track instance
    init(id: String, title: String, author: String, audio: URL, artwork: URL, description: String, duration: CMTime) {
        self.id = id
        self.title = title
        self.author = author
        self.audio = audio
        self.artwork = artwork
        self.description = description
        self.duration = duration
    }
    
    // Initializer to create a Track instance from a FirestoreTrackModel and a StorageManager asynchronously
    init(from model: FirestoreTrackModel, storageManager manager: StorageManager) async throws {
        let audioURL = try await manager.get(from: model.audio)
        let artworkURL = try await manager.get(from: model.artwork)
        self.id = model.id
        self.title = model.title
        self.author = model.author
        self.description = model.description
        self.audio = audioURL
        self.artwork = artworkURL
        self.duration = try await AVURLAsset(url: audioURL).load(.duration)
    }
    
    // Initializer to create a Track instance from a FirestoreTrackModel asynchronously
    init(from model: FirestoreTrackModel) async throws {
        guard let audioURL = URL(string: model.audio),
              let artworkURL = URL(string: model.artwork) else { throw URLError(.badURL) }
        self.id = model.id
        self.title = model.title
        self.author = model.author
        self.description = model.description
        self.audio = audioURL
        self.artwork = artworkURL
        self.duration = try await AVURLAsset(url: audioURL).load(.duration)
    }
    
    // Offline test instance for Track
    static let offlineInstance = Track(id: "DHA4WlsFJMJCfCK1DTu3", title: "Money so big", author: "Cosmi girl", audio: URL(string: "https://youtu.be/T_ASKLftsLs")!, artwork: URL(string: "https://www.udiscovermusic.com/wp-content/uploads/2022/04/2-Alive-Geek-Pack_-Explicit-Cover-2.jpg")!, description: "Immerse yourself in a sonic cocoon of tranquility with our carefully curated selection of Lo-Fi music, expertly crafted to enhance your study sessions. Designed to be both captivating and unobtrusive, our Lo-Fi playlist is the ideal companion for your academic pursuits.\n\nAs you delve into your studies, the gentle ebb and flow of Lo-Fi beats will transport you to a realm of focused concentration. The soothing melodies and understated rhythms create an ambiance that effortlessly melds with your surroundings, fostering a sense of calm productivity.\n\nThe tapestry of Lo-Fi melodies is woven with warmth and nostalgia, yet remains contemporary in its composition. Subtle crackles and imperfections in the audio offer a touch of authenticity, reminiscent of vintage vinyl records. These delightful imperfections add to the allure, inviting you to embrace the present moment while your mind remains steadfast on your scholarly endeavors.\n\nWhether you're tackling complex equations, diving into literature, or researching vast realms of knowledge, our Lo-Fi music provides a backdrop that nurtures your cognitive faculties. The unobtrusive nature of the music allows your thoughts to flow freely, unburdened by distractions.\n\nAllow the atmospheric soundscape to guide you through your study sessions, enhancing your focus, concentration, and retention. Each note is a stepping stone towards your academic goals, creating an environment where learning becomes an invigorating journey.\n\nElevate your study experience with our meticulously curated Lo-Fi music, where the harmonious marriage of melody and ambiance paves the way for a fruitful and enriching scholarly adventure. Discover the harmonious intersection of auditory delight and academic prowess as you indulge in the world of Lo-Fi music for studying.", duration: CMTime(seconds: 60 * 59, preferredTimescale: 600))
}
