//
//  MobileDataCache.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

protocol MobileDataCache {
    typealias Result = Swift.Result<Void, Error>

    func save(_ records: [RecordItem], completion: @escaping (Result) -> Void)
}
