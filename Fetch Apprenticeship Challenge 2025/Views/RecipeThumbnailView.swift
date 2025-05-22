//
//  RecipeThumbnailView.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 5/21/25.
//

import SwiftUI

struct RecipeThumbnailView: View {
  let url: URL
  @State private var uiImage: UIImage?
  @State private var isLoading = false

  var body: some View {
    Group {
      if let image = uiImage {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else if isLoading {
        ProgressView()
              .onAppear { load() }
      } else {
        Color.gray.opacity(0.1)
          .onAppear { load() }
      }
    }
  }

  private func load() {
    isLoading = true
    Task {
      do {
        let img = try await ImageLoader.shared.loadImage(from: url.absoluteString)
        uiImage = img
      } catch { }
      isLoading = false
    }
  }
}
