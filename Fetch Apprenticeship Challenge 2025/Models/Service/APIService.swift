//
//  APIService.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/16/25.
//

import SwiftUI
import Foundation



final class APIService {
    private let session: URLSession
    private let endpoints: [EndpointType: String] = [
        .normal: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json",
        .malformed: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes-malformed.json",
        .empty: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes-empty.json"
    ]
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchRecipes(endpoint: EndpointType = .normal) async throws -> [Recipe] {
        guard let urlString = endpoints[endpoint],
              let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)

        try validate(response: response)
        return try decode(data: data)
    }
    
    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        print("no errors were thrown")
    }
    
    private func decode(data: Data) throws -> [Recipe] {
        do {
            let decoder = JSONDecoder()
            let recipes = try decoder.decode(RecipeResponse.self, from: data).recipes
            
            return recipes
        } catch {
            print("Decoding failure:", error)
            throw APIError.decodingError(error)
        }
    }
}

enum EndpointType {
    case normal, malformed, empty
}

enum APIError: Error, LocalizedError {
    case invalidURL, invalidResponse, httpError(Int), decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid endpoint URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let error): return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
