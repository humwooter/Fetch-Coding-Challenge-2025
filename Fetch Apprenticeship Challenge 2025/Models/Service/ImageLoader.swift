//
//  ImageLoader.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/16/25.
//

import SwiftUI
import Foundation

// image loader with custom caching
actor ImageLoader {
    enum ImageLoaderError: Error {
        case invalidURL
        case networkError(underlying: Error)
        case invalidData
        case diskReadError(underlying: Error)
        case diskWriteError(underlying: Error)
    }
    
    static let shared = ImageLoader()
    private let memoryCache = NSCache<NSString, UIImage>()
    private var fileManager = FileManager.default
    /// URLSession used for network requests – injected for unit‑testing
    private let session: URLSession
    private var diskCacheURL: URL
    
     init() {
         self.session = .shared
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCacheURL = paths[0].appendingPathComponent("ImageCache")
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    init(diskCacheURL: URL,
         session: URLSession = .shared,
         fileManager: FileManager = .default) {
        self.diskCacheURL = diskCacheURL
        self.session      = session
        self.fileManager  = fileManager
        try? fileManager.createDirectory(at: diskCacheURL,
                                         withIntermediateDirectories: true)
    }
    
    
    func loadImage(from urlString: String) async throws -> UIImage {
        let cacheKey = urlString as NSString
        
        // 1. memory cache check ( o(1) in memory lookup. immediate hit if recently used)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 2. disk cache check
        if let diskImage = try? await loadFromDisk(urlString: urlString) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // 3. network fetch ( highest latency but fresh data) )
        guard
            let url = URL(string: urlString),
            let scheme = url.scheme, !scheme.isEmpty,
            let host = url.host,   !host.isEmpty
        else {
            throw ImageLoaderError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else {
                throw ImageLoaderError.invalidData
            }
            // cache to memory
            memoryCache.setObject(image, forKey: cacheKey)
            // cache to disk in background
            Task.detached(priority: .background) {
                do {
                    try await self.saveToDisk(image: data, urlString: urlString)
                } catch {
                    // optionally log disk write error
                }
            }
            return image
        } catch {
            throw ImageLoaderError.networkError(underlying: error)
        }
    }
    
    /// generate a consistent cache filename from any URL string
    private func cacheFilename(for urlString: String) -> String {
        if let url = URL(string: urlString) {
            let segments = url.pathComponents
            let uuid: String = {
                guard let idx = segments.firstIndex(of: "photos"),
                      segments.indices.contains(idx+1)
                else { return "image" }
                return segments[idx+1]
            }()
            let imageName = url.lastPathComponent      // e.g. "small.jpg"
            return "\(uuid)_\(imageName)"              // e.g. "abc123_small.jpg"
        } else {
            return urlString.components(separatedBy: "/").last ?? "image"
        }
    }

    func saveToDisk(image data: Data, urlString: String) async throws {
        let filename = cacheFilename(for: urlString)
        let fileURL = diskCacheURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
    }

    func loadFromDisk(urlString: String) async throws -> UIImage {
        let filename = cacheFilename(for: urlString)
        let fileURL = diskCacheURL.appendingPathComponent(filename)

        let data  = try Data(contentsOf: fileURL)
        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.invalidData
        }
        return image
    }
}
