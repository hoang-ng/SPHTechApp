//
//  LocalMobileDataServiceTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class LocalMobileDataServiceTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = NSError(domain: "error", code: 0)
        
        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    func test_load_deliverNoDataOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in
        }
        store.completeRetrieval(with: NSError(domain: "error", code: 0))
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in
        }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.111, quater: "2020-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.111, quater: "2020-Q2")
        
        sut.save([item1, item2]) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedData])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "error", code: 0)
        
        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.111, quater: "2020-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.111, quater: "2020-Q2")
        
        sut.save([item1, item2]) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedData])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "error", code: 0)
        
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = NSError(domain: "error", code: 0)
        
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    private func expect(_ sut: LocalMobileDataService, toCompleteWith expectedResult: LocalMobileDataService.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(_ sut: LocalMobileDataService, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.111, quater: "2020-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.111, quater: "2020-Q2")
        
        sut.save([item1, item2]) { result in
            if case let Result.failure(error) = result { receivedError = error }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalMobileDataService, store: MobileDataStoreSpy) {
        let store = MobileDataStoreSpy()
        let sut = LocalMobileDataService(store: store)
        return (sut, store)
    }
    
    class MobileDataStoreSpy: MobileDataStore {
        
        enum ReceivedMessage: Equatable {
            case deleteCachedData
            case insert([LocalRecordItem])
            case retrieve
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        private var retrievalCompletions = [RetrievalCompletion]()
        
        func deleteCachedRecord(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedData)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](.failure(error))
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](.success(()))
        }
        
        func insert(_ records: [LocalRecordItem], completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(records))
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](.failure(error))
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](.success(()))
        }
        
        func retrieve(completion: @escaping RetrievalCompletion) {
            retrievalCompletions.append(completion)
            receivedMessages.append(.retrieve)
        }
        
        func completeRetrieval(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }
        
        func completeRetrievalWithEmptyCache(at index: Int = 0) {
            retrievalCompletions[index](.success(.none))
        }
        
        func completeRetrieval(with records: [LocalRecordItem], at index: Int = 0) {
            retrievalCompletions[index](.success(records))
        }
    }
}
