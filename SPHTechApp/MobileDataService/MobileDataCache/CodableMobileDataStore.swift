//
//  CodableMobileDataStore.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

final class CodableMobileDataStore: MobileDataStore {
    
    private struct Cache: Codable {
        let records: [CodableRecordItem]
    
        var localRecords: [LocalRecordItem] {
            return records.map { $0.local }
        }
    }
    
    private struct CodableRecordItem: Codable {
        private let id: Int
        private let volumeOfMobileData: Float
        private let quarter: String
        
        init(_ item: LocalRecordItem) {
            id = item.id
            volumeOfMobileData = item.volumeOfMobileData
            quarter = item.quarter
        }
        
        var local: LocalRecordItem {
            return LocalRecordItem(volumeOfMobileData: volumeOfMobileData, quarter: quarter, id: id)
        }
    }
    
    private let storeURL: URL
    
    private let queue = DispatchQueue(label: "\(CodableMobileDataStore.self)Queue", qos: .userInitiated, attributes: .concurrent)

    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func insert(_ records: [LocalRecordItem], completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            do {
                let encoder = JSONEncoder()
                let cache = Cache(records: records.map(CodableRecordItem.init))
                let encoded = try encoder.encode(cache)
                try encoded.write(to: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.success(.none))
            }
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.success(CachedRecord(cache.localRecords)))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedRecord(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.success(()))
            }
        }
    }
}
