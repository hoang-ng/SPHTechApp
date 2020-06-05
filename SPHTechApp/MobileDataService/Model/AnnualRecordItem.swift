//
//  AnnualRecordItem.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

struct AnnualRecordItem {
    let records: [RecordItem]
    let year: String
    
    var volume: Float {
        get {
            return records.reduce(0.0, { (volume, item) -> Float in
                return volume + item.volumeOfMobileData
            })
        }
    }
    
    var isDecrease: Bool {
        get {
            for i in 1..<records.count {
                if records[i].volumeOfMobileData < records[i - 1].volumeOfMobileData {
                    return true
                }
            }
            return false
        }
    }
    
    init(year: String, records: [RecordItem]) {
        self.records = records.sorted { $0.id < $1.id }
        self.year = year
    }
}

struct AnnualRecordItems {
    let annualRecords: [AnnualRecordItem]
    
    init(records: [RecordItem]) {
        var dict = [String: [RecordItem]]()
        
        for record in records {
            let year = record.quater.components(separatedBy: "-")[0]
            if var annualRecords = dict[year] {
                annualRecords.append(record)
                dict[year] = annualRecords
            } else {
                var annualRecords = [RecordItem]()
                annualRecords.append(record)
                dict[year] = annualRecords
            }
        }
        var annualItems = [AnnualRecordItem]()
        
        for (year, items) in dict {
            annualItems.append(AnnualRecordItem(year: year, records: items))
        }
        self.annualRecords = annualItems.sorted { $0.year < $1.year }
    }
}
