//
//  MobileDataServiceCacheDecoratorTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/6/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class MobileDataServiceCacheDecoratorTests: XCTestCase {
    func test_load_deliversDataOnLoaderSuccess() {
        let item = RecordItem(id: 1, volumeOfMobileData: 0.55, quater: "2020-Q1")
        let sut = makeSUT(loaderResult: .success([item]))

        expect(sut, toCompleteWith: .success([item]))
    }
    
    func test_load_deliversErrorOnLoaderFailure() {
        let error = NSError(domain: "error", code: 0)
        
        let sut = makeSUT(loaderResult: .failure(error))

        expect(sut, toCompleteWith: .failure(error))
    }
    
    func test_load_cachesLoadedDataOnLoaderSuccess() {
        let cache = CacheSpy()
        let item = RecordItem(id: 1, volumeOfMobileData: 0.55, quater: "2020-Q1")
        let sut = makeSUT(loaderResult: .success([item]), cache: cache)

        sut.load { _ in }
        
        XCTAssertEqual(cache.messages, [.save([item])], "Expected to cache loaded record on success")
    }
    
    func test_load_doesNotCacheOnLoaderFailure() {
        let cache = CacheSpy()
        let error = NSError(domain: "error", code: 0)
        let sut = makeSUT(loaderResult: .failure(error), cache: cache)

        sut.load { _ in }

        XCTAssertTrue(cache.messages.isEmpty, "Expected not to cache records on load error")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(loaderResult: MobileDataService.Result, cache: CacheSpy = .init(), file: StaticString = #file, line: UInt = #line) -> MobileDataService {
        let loader = MobileDataServiceStub(result: loaderResult)
        let sut = MobileDataServiceCacheDecorator(decoratee: loader, cache: cache)
        return sut
    }
    
    func expect(_ sut: MobileDataService, toCompleteWith expectedResult: MobileDataService.Result, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
                
        wait(for: [exp], timeout: 1.0)
    }
    
    private class CacheSpy: MobileDataCache {
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            case save([RecordItem])
        }
        
        func save(_ records: [RecordItem], completion: @escaping (MobileDataCache.Result) -> Void) {
            messages.append(.save(records))
            completion(.success(()))
        }
    }
}
