//
//  ImageLoaderTests.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/19/25.

import XCTest
@testable import Fetch_Apprenticeship_Challenge_2025

final class ImageLoaderTests: XCTestCase {


    private var tempDir: URL!
    private var session: URLSession!
    private var loader: ImageLoader!

    override func setUp() {
        super.setUp()

        // fresh temp folder so tests never collide
        tempDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        // urlsession that routes every request through stuburlprotocol
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: cfg)

        // imageLoader that uses our temp folder and stubbed session
        loader = ImageLoader(diskCacheURL: tempDir, session: session)

        // reset stub state
        StubURLProtocol.testData   = nil
        StubURLProtocol.statusCode = 200
        StubURLProtocol.error      = nil
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir  = nil
        session  = nil
        loader   = nil
        super.tearDown()
    }


    // error: malformed url string → invalidURL
    func testLoadImage_withInvalidURL_throwsInvalidURL() async {
        do {
            _ = try await loader.loadImage(from: "invalid url example")
            XCTFail("expected invalidURL")
        } catch ImageLoader.ImageLoaderError.invalidURL {
            // ok
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // error: network failure wrapped in networkError
    func testLoadImage_propagatesNetworkError() async {
        let url = "https://example.com/img.png"
        StubURLProtocol.error = URLError(.timedOut)

        do {
            _ = try await loader.loadImage(from: url)
            XCTFail("expected network error")
        } catch ImageLoader.ImageLoaderError.networkError(let underlying) {
            XCTAssertEqual((underlying as? URLError)?.code, .timedOut)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // error: server returns bytes that aren't a decodable image
    func testLoadImage_withNonImageData_throwsInvalidData() async {
        let url = "https://example.com/img.png"
        StubURLProtocol.testData = Data("garbage".utf8)

        do {
            _ = try await loader.loadImage(from: url)
            XCTFail("expected invalidData")
        } catch ImageLoader.ImageLoaderError.networkError(let inner) {
            // unwrap and pattern-match because the enum isn't equatable
            guard case .invalidData = inner as? ImageLoader.ImageLoaderError else {
                XCTFail("unexpected inner error \(inner)")
                return
            }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // error: file exists on disk but contains corrupt bytes
    func testLoadFromDisk_withCorruptedFile_throwsInvalidData() async throws {
        // write bogus bytes using same naming logic imageLoader uses
        let bad = tempDir.appendingPathComponent("abc123_small.jpg")
        try "broken".data(using: .utf8)!.write(to: bad)

        do {
            _ = try await loader.loadFromDisk(
                urlString: "https://example.com/photos/abc123/small.jpg")
            XCTFail("expected invalidData")
        } catch ImageLoader.ImageLoaderError.invalidData {
            // ok
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }
}
