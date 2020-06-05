//
//  RemoteRecordLoader.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

class RemoteMobileDataService: MobileDataService {
    
    private let url: URL
    private let client: HTTPClient
    
    public typealias Result = MobileDataService.Result
    
    enum Error: Swift.Error {
        case invalidData
        case connectivity
    }
    
    init(_ url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                completion(RemoteMobileDataService.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try RecordItemMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteRecordItem {
    func toModels() -> [RecordItem] {
        return map { RecordItem(id: $0._id, volumeOfMobileData: ($0.volume_of_mobile_data as NSString).floatValue, quater: $0.quarter) }
    }
}
