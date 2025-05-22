//
//  Recipe.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/16/25.
//

import SwiftUI
import Foundation


struct Recipe: Codable, Identifiable {
    let id: String //to conform to identifiable protocol
    let cuisine: String
    let name: String
    let photoURLLarge: String?
    let photoURLSmall: String?
    let sourceURL: String?
    let youtubeURL: String?
    
    // explicit coding keys for snake case to camel case conversion
    enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case cuisine
        case name
        case photoURLLarge = "photo_url_large"
        case photoURLSmall = "photo_url_small"
        case sourceURL = "source_url"
        case youtubeURL = "youtube_url"
    }
}
