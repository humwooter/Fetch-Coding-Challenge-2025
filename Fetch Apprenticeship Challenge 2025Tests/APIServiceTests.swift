//
//  APIServiceTests.swift
//  Fetch Apprenticeship Challenge 2025
//
//  Created by Katyayani G. Raman on 4/19/25.
//

import XCTest
@testable import Fetch_Apprenticeship_Challenge_2025

class StubURLProtocol: URLProtocol {
    private static let queue = DispatchQueue(label: "StubURLProtocol")
    private static var _testData: Data?
    private static var _statusCode: Int = 200
    private static var _error: Error?
    
    static var testData: Data? {
        get { queue.sync { _testData } }
        set { queue.sync { _testData = newValue } }
    }
    
    static var statusCode: Int {
        get { queue.sync { _statusCode } }
        set { queue.sync { _statusCode = newValue } }
    }
    
    static var error: Error? {
        get { queue.sync { _error } }
        set { queue.sync { _error = newValue } }
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    
    override func startLoading() {
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = Self.testData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
}
final class APIServiceTests: XCTestCase {
    var service: APIService!
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        StubURLProtocol.testData = nil
        StubURLProtocol.statusCode = 200
        StubURLProtocol.error = nil
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: config)
        service = APIService(session: session)
    }
    

    // verifies that a valid response with one recipe is decoded correctly
    func testFetchRecipes_withValidResponse_returnsRecipes() async throws {
        let mockJSON = """
        {
            "recipes": [
                {
                    "uuid": "1",
                    "name": "Nasi Lemak",
                    "cuisine": "Malaysian",
                    "photo_url_large": "https://example.com/large.jpg",
                    "photo_url_small": "https://example.com/small.jpg",
                    "source_url": "https://example.com/recipe",
                    "youtube_url": "https://www.youtube.com/watch?v=1"
                }
            ]
        }
        """.data(using: .utf8)!
        
        StubURLProtocol.testData = mockJSON
        StubURLProtocol.statusCode = 200
        
        let recipes = try await service.fetchRecipes(endpoint: .normal)
        
        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes.first?.id, "1")
        XCTAssertEqual(recipes.first?.cuisine, "Malaysian")
    }
    
    // Edge Cases

    // verifies that an empty recipe array returns an empty list
    func testFetchRecipes_withEmptyArrayResponse_returnsEmptyList() async throws {
        let emptyJSON = """
        { "recipes": [] }
        """.data(using: .utf8)!
        
        StubURLProtocol.testData = emptyJSON
        StubURLProtocol.statusCode = 200
        
        let recipes = try await service.fetchRecipes(endpoint: .empty)
        
        XCTAssertTrue(recipes.isEmpty)
    }

    // verifies that a server error results in a thrown network error
    func testFetchRecipes_withServerError_throwsNetworkError() async {
        StubURLProtocol.statusCode = 500
        StubURLProtocol.error = URLError(.badServerResponse)
        
        do {
            _ = try await service.fetchRecipes(endpoint: .normal)
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    //Malformed Data Tests

    // verifies that invalid json structure throws a decoding error
    func testFetchRecipes_withInvalidJSON_throwsDecodingError() async {
       let invalidJSON = """
       { "recipes": [ { "uuid": "1", "name": "Foo"  // missing closing braces
       """.data(using: .utf8)!
       
       StubURLProtocol.testData = invalidJSON
       StubURLProtocol.statusCode = 200
       
       do {
         _ = try await service.fetchRecipes(endpoint: .malformed)
         XCTFail("Expected decoding error")
       }
       catch APIError.decodingError(let underlying) {
         XCTAssertTrue(underlying is DecodingError)
       }
       catch {
         XCTFail("Unexpected error type: \(error)")
       }
     }

    // verifies that missing required fields throws a decoding error
    func testFetchRecipes_withMissingRequiredFields_throwsDecodingError() async {
       let incompleteJSON = """
       {
         "recipes": [
           { "uuid": "2", "name": "Pho" }
         ]
       }
       """.data(using: .utf8)!
       
       StubURLProtocol.testData = incompleteJSON
       StubURLProtocol.statusCode = 200
       
       do {
         _ = try await service.fetchRecipes(endpoint: .normal)
         XCTFail("Expected decoding error")
       }
       catch APIError.decodingError(let underlying) {
         XCTAssertTrue(underlying is DecodingError)
       }
       catch {
         XCTFail("Unexpected error type: \(error)")
       }
     }
    
    //Network Failure Tests

    // verifies that a network connection error is thrown when offline
    func testFetchRecipes_withConnectionError_throwsNetworkError() async {
        StubURLProtocol.error = URLError(.notConnectedToInternet)
        
        do {
            _ = try await service.fetchRecipes(endpoint: .normal)
            XCTFail("Expected network error")
        } catch let urlError as URLError {
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
