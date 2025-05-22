//
//  RecipeListViewModel.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/16/25.
//

import SwiftUI
import Foundation

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    var showingError: Bool {
        error != nil
    } //convenience flag for views
    
    private let service: APIService

    init(service: APIService = APIService()) {
        self.service = service
    }

    //fetch recipes using the normal endpoint
    func fetchRecipes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchRecipes(endpoint: .normal)
            recipes = fetched
            error = nil
        } catch {
            recipes = []
            self.error = error
        }
    }
}
