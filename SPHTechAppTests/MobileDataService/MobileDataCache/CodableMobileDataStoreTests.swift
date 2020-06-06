//
//  CodableMobileDataStoreTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation
import XCTest
@testable import SPHTechApp

class CodableMobileDataStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .success(.none))
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        insert([item1, item2], to: sut)
        
        expect(sut, toRetrieve: .success([item1, item2]))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        let error = NSError(domain: "any error", code: 0)
        expect(sut, toRetrieve: .failure(error))
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        let insertionError = insert([item1, item2], to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully")
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        insert([item1, item2], to: sut)
        
        let insertionError = insert([item1, item2], to: sut)
        
        XCTAssertNil(insertionError, "Expected to override cache successfully")
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        insert([item1, item2], to: sut)
        insert([item1, item2], to: sut)
        
        expect(sut, toRetrieve: .success([item1, item2]))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        let insertionError = insert([item1, item2], to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        insert([item1, item2], to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        insert([item1, item2], to: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .success(.none))
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let item1 = LocalRecordItem(volumeOfMobileData: 0.1, quarter: "2020-Q1", id: 1)
        let item2 = LocalRecordItem(volumeOfMobileData: 0.4, quarter: "2020-Q2", id: 2)
        
        let op1 = expectation(description: "Operation 1")
        sut.insert([item1, item2]) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedRecord { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert([item1, item2]) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }

    // - MARK: Helpers
    
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> MobileDataStore {
        let sut = CodableMobileDataStore(storeURL: storeURL ?? testSpecificStoreURL())
        return sut
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        do {
            let cachesDirectory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return cachesDirectory
        } catch {
            print(error.localizedDescription)
        }
        
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    @discardableResult
    func insert(_ records: [LocalRecordItem], to sut: MobileDataStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(records) { result in
            if case let Result.failure(error) = result { insertionError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: MobileDataStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedRecord { result in
            if case let Result.failure(error) = result { deletionError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    func expect(_ sut: MobileDataStore, toRetrieve expectedResult: MobileDataStore.RetrievalResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.none), .success(.none)),
                 (.failure, .failure):
                break
                
            case let (.success(.some(expected)), .success(.some(retrieved))):
                XCTAssertEqual(retrieved, expected, file: file, line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
