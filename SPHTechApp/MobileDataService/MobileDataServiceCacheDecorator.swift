//
//  MobileDataServiceCacheDecorator.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

final class MobileDataServiceCacheDecorator: MobileDataService {
    private let decoratee: MobileDataService
    private let cache: MobileDataCache
    
    public init(decoratee: MobileDataService, cache: MobileDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func load(completion: @escaping (MobileDataService.Result) -> Void) {
        decoratee.load { [weak self] result in
            completion(result.map { records in
                self?.cache.save(records, completion: { result in
                })
                return records
            })
        }
    }
}
