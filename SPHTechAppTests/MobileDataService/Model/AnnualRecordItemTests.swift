//
//  AnnualRecordItemTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
@testable import SPHTechApp

class AnnualRecordItemTests: XCTestCase {
    
    func test_annualRecordItem() {
        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.2, quater: "2019-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.3, quater: "2019-Q2")
        
        let item3 = RecordItem(id: 3, volumeOfMobileData: 0.5, quater: "2020-Q1")
        let item4 = RecordItem(id: 4, volumeOfMobileData: 0.3, quater: "2020-Q2")
        
        let annualRecord = AnnualRecordItems(records: [item1, item2, item3, item4])
        XCTAssertTrue(annualRecord.annualRecords.count == 2)
        XCTAssertTrue(annualRecord.annualRecords[0].year == "2019")
        XCTAssertTrue(annualRecord.annualRecords[0].volume == 0.5)
        XCTAssertTrue(annualRecord.annualRecords[0].isDecrease == false)
        
        XCTAssertTrue(annualRecord.annualRecords[1].year == "2020")
        XCTAssertTrue(annualRecord.annualRecords[1].volume == 0.8)
        XCTAssertTrue(annualRecord.annualRecords[1].isDecrease == true)
    }
}
