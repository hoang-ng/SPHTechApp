//
//  RemoteMobileDataServiceTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class RemoteMobileDataServiceTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestUrls.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "http://any-url")!
        
        let (sut, client) = makeSUT()
        sut.load() { _ in }
        
        XCTAssertEqual(client.requestUrls, [url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteMobileDataService.Error.connectivity), when: {
            client.complete(with: .connectivity)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteMobileDataService.Error.invalidData), when: {
                client.complete(with: code, data: Data(), at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        let invalidJSON = Data("invalid json".utf8)
        
        expect(sut, toCompleteWith: .failure(RemoteMobileDataService.Error.invalidData), when: {
            client.complete(with: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoRecordsOnOn200HTTPResponseWithEmptyJSON() {
        let (sut, client) = makeSUT()
        let emptyListJSON = makeItemsJSON([])

        expect(sut, toCompleteWith: .success([]), when: {
            client.complete(with: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversRecordsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        let (item1, item1JSON) = makeItem(id: 1, volume: 0.000718, quater: "2005-Q3")
        let (item2, item2JSON) = makeItem(id: 2, volume: 0.000801, quater: "2005-Q4")

        let itemsJSON = makeItemsJSON([item1JSON, item2JSON])

        expect(sut, toCompleteWith: .success([item1, item2]), when: {
            client.complete(with: 200, data: itemsJSON)
        })
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteMobileDataService? = RemoteMobileDataService(url, client: client)

        var capturedResults = [Result<[RecordItem], Swift.Error>]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(with: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "http://any-url")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteMobileDataService, client: HTTPClientSpy) {
        let url = URL(string: "http://any-url")!
        let client = HTTPClientSpy()
        let sut = RemoteMobileDataService(url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClient.Result) -> ())]()
        var requestUrls: [URL] {
            return messages.map {
                $0.url
            }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> ()) {
            messages.append((url, completion))
        }
        
        func complete(with error: RemoteMobileDataService.Error) {
            messages.last?.completion(.failure(error))
        }
        
        func complete(with statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[0].url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
    
    private func makeItem(id: Int, volume: Float, quater: String) -> (model: RecordItem, json: [String: Any]) {
        let item = RecordItem(id: id, volumeOfMobileData: volume, quater: quater)
        
        let json = [
            "_id": id,
            "volume_of_mobile_data": "\(volume)",
            "quarter": quater
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let records = ["records": items]
        let json = ["result": records]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteMobileDataService, toCompleteWith expectedResult: RemoteMobileDataService.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
                
            case let (.failure(receivedError as RemoteMobileDataService.Error), .failure(expectedError as RemoteMobileDataService.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
