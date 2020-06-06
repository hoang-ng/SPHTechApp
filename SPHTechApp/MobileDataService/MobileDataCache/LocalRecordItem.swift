//
//  LocalRecordItem.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

struct LocalRecordItem: Decodable, Equatable {
    let volumeOfMobileData: Float
    let quarter: String
    let id: Int
}
