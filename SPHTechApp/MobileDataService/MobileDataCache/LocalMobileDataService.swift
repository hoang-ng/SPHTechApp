//
//  RemoteMobileDataService.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

final class LocalMobileDataService {
    private let store: MobileDataStore
    
    init(store: MobileDataStore) {
        self.store = store
    }
}

extension LocalMobileDataService: MobileDataCache {
    public typealias SaveResult = MobileDataCache.Result

    public func save(_ records: [RecordItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedRecord { [weak self] deletionResult in
            guard let self = self else { return }
            
            switch deletionResult {
            case .success:
                self.cache(records, with: completion)
            
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ records: [RecordItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(records.toLocal()) { [weak self] insertionResult in
            guard self != nil else { return }
            
            completion(insertionResult)
        }
    }
}

extension LocalMobileDataService: MobileDataService {
    public typealias LoadResult = MobileDataService.Result

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(.some(cache)):
                completion(.success(cache.toModels()))
            case .success:
                completion(.success([]))
            }
        }
    }
}

private extension Array where Element == RecordItem {
    func toLocal() -> [LocalRecordItem] {
        return map { LocalRecordItem(volumeOfMobileData: $0.volumeOfMobileData, quarter: $0.quater, id: $0.id) }
    }
}

private extension Array where Element == LocalRecordItem {
    func toModels() -> [RecordItem] {
        return map { RecordItem(id: $0.id, volumeOfMobileData: $0.volumeOfMobileData, quater: $0.quarter) }
    }
}
