//
//  RemoteMobileDataServiceTests.swift
//  SPHTechAppIntegrationTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class RemoteMobileDataServiceTests: XCTestCase {

    func test_endToEndTestServerGETRecordsResult_matchesFixedData() {
        var expectedRecords = [RemoteRecordItem]()
        
        if let path = Bundle(for: RemoteMobileDataServiceTests.self).path(forResource: "records", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let response = HTTPURLResponse(url: URL(string: "http://any-url.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                expectedRecords = try RecordItemMapper.map(data, from: response)
              } catch {
                   XCTFail("Expected successful load sample data, got \(error) instead")
              }
        }
        
        switch getMobileDataResult() {
        case let .success(records)?:
            XCTAssertEqual(records.count, 59, "Expected 59 records")
            XCTAssertEqual(records, expectedRecords.toModels())
        case let .failure(error)?:
            XCTFail("Expected successful result, got \(error) instead")
            
        default:
            XCTFail("Expected successful result, got no result instead")
        }
    }
    
    // MARK: - Helpers
    
    private func getMobileDataResult(file: StaticString = #file, line: UInt = #line) -> MobileDataService.Result? {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteMobileDataService(serverURL, client: client)
        
        let exp = expectation(description: "Wait for load completion")
        
        var receivedResult: MobileDataService.Result?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        
        return receivedResult
    }
    
    private var serverURL: URL {
        return URL(string: "https://data.gov.sg/api/action/datastore_search?resource_id=a807b7ab-6cad-4aa6-87d0-e283a7353a0f")!
    }
}

private extension Array where Element == RemoteRecordItem {
    func toModels() -> [RecordItem] {
        return map { RecordItem(id: $0._id, volumeOfMobileData: ($0.volume_of_mobile_data as NSString).floatValue, quater: $0.quarter) }
    }
}
