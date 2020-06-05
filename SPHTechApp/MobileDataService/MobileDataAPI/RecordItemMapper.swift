//
//  RecordItemMapper.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

class RecordItemMapper {
    
    private struct Root: Decodable {
        let result: Result
    }
    
    private struct Result: Decodable {
        let records: [RemoteRecordItem]
    }
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteRecordItem] {
        guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteMobileDataService.Error.invalidData
        }

        return root.result.records
    }
}
