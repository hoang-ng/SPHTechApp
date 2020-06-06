//
//  MobileDataStore.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

typealias CachedRecord = ([LocalRecordItem])

protocol MobileDataStore {
    typealias DeletionResult = Result<Void, Error>
    typealias DeletionCompletion = (DeletionResult) -> Void
    
    typealias InsertionResult = Result<Void, Error>
    typealias InsertionCompletion = (InsertionResult) -> Void
    
    typealias RetrievalResult = Result<CachedRecord?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    func deleteCachedRecord(completion: @escaping DeletionCompletion)
    func insert(_ records: [LocalRecordItem], completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
