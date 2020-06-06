//
//  MobileDataServiceCompositeTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/6/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class MobileDataServiceCompositeTests: XCTestCase {
    func test_load_deliversRemoteDataOnRemoteServiceSuccess() {
        let remoteRecord = RecordItem(id: 1, volumeOfMobileData: 0.5, quater: "2020-Q1")
        let localRecord = RecordItem(id: 2, volumeOfMobileData: 0.3, quater: "2019-Q1")
        
        
        let sut = makeSUT(remoteResult: .success([remoteRecord]), localResult: .success([localRecord]))

        expect(sut, toCompleteWith: .success([remoteRecord]))
    }
    
    func test_load_deliversLocalDataOnRemoteServiceFailure() {
        let localRecord = RecordItem(id: 2, volumeOfMobileData: 0.3, quater: "2019-Q1")
        let error = NSError(domain: "error", code: 0)
        
        let sut = makeSUT(remoteResult: .failure(error), localResult: .success([localRecord]))

        expect(sut, toCompleteWith: .success([localRecord]))
    }
    
    func test_load_deliversErrorOnBothRemoteAndLocalServiceFailure() {
        let error = NSError(domain: "error", code: 0)
        
        let sut = makeSUT(remoteResult: .failure(error), localResult: .failure(error))
        
        expect(sut, toCompleteWith: .failure(error))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(remoteResult: MobileDataService.Result, localResult: MobileDataService.Result, file: StaticString = #file, line: UInt = #line) -> MobileDataService {
        let remoteService = MobileDataServiceStub(result: remoteResult)
        let localService = MobileDataServiceStub(result: localResult)
        let sut = MobileDataServiceComposite(remoteService: remoteService, localService: localService)
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
}

class MobileDataServiceStub: MobileDataService {
    private let result: MobileDataService.Result
    
    init(result: MobileDataService.Result) {
        self.result = result
    }

    func load(completion: @escaping (MobileDataService.Result) -> Void) {
        completion(result)
    }
}
