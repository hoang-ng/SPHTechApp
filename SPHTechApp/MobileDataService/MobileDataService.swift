//
//  MobileDataService.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

protocol MobileDataService {
    typealias Result = Swift.Result<[RecordItem], Error>
    
    func load(completion: @escaping (Result) -> Void)
}
