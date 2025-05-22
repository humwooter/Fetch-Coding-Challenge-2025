//
//  RecipeListView.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/16/25.
//
import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeListViewModel()
    @State private var showNetworkAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.recipes.isEmpty {
                    if viewModel.isLoading {
                        ProgressView("Loading recipes...")
                    } else {
                        filteredRecipesView()
                    }
                } else if !viewModel.showingError {
                    filteredRecipesView()
                }
            }
            .navigationTitle("Recipes")
            .onAppear {
                if viewModel.recipes.isEmpty {
                    Task { await viewModel.fetchRecipes() }
                }
            }
        }
        .alert(
            "Network connection seems to be offline.",
            isPresented: $showNetworkAlert
        ) {}
    }
    
    private func EmptyStateView() -> some View {
        VStack {
            Text("No recipes available")
                .foregroundColor(.secondary)
            Text("Please check your connection and try again.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func filteredRecipesView() -> some View {
        List(viewModel.recipes) { recipe in
            NavigationLink {
                recipeDetailView(recipe)
            } label: {
                recipeRow(recipe)
            }
        }
    }
    
    
    
    @ViewBuilder
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            if let urlStr = recipe.photoURLSmall, let url = URL(string: urlStr) {
                RecipeThumbnailView(url: url)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Color.gray.opacity(0.1)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func recipeThumbnail(_ url: URL) -> some View {
        Group {
            @State var uiImage: UIImage?
            @State var isLoading = false
            
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.1)
                    .onAppear {
                        isLoading = true
                        Task {
                            do {
                                let img = try await ImageLoader.shared.loadImage(from: url.absoluteString)
                                uiImage = img
                            } catch {
                                // ignore
                            }
                            isLoading = false
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func recipeDetailView(_ recipe: Recipe) -> some View {
        List {
            
            // recipe info section
            Section {
                if let imageURLString = recipe.photoURLLarge ?? recipe.photoURLSmall,
                   let imageURL = URL(string: imageURLString) {
                    Section {
                        RecipeThumbnailView(url: imageURL)
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                            .frame(height: 300)
//                            .listRowInsets(EdgeInsets()) // removes padding around the image
                    }
                }
                Text(recipe.cuisine)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // source link section
            if let source = recipe.sourceURL,
               let sourceURL = URL(string: source) {
                Section {
                    Link("View Recipe Source", destination: sourceURL)
                } header: {
                    Label("Source", systemImage: "link")
                        .font(.headline)
                }
            }
            
            // youtube link section
            if let youtube = recipe.youtubeURL,
               let youtubeURL = URL(string: youtube) {
                Section {
                    Link("Watch on YouTube", destination: youtubeURL)
                } header: {
                    Label("YouTube", systemImage: "play.rectangle.fill")
                        .font(.headline)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(recipe.name)
//        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("recipe details: \(recipe)")
        }
    }
}
    
