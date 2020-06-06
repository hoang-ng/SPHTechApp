//
//  MobileDataServiceComposite.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation

class MobileDataServiceComposite: MobileDataService {
    private let remoteService: MobileDataService
    private let localService: MobileDataService

    init(remoteService: MobileDataService, localService: MobileDataService) {
        self.remoteService = remoteService
        self.localService = localService
    }
    
    public func load(completion: @escaping (MobileDataService.Result) -> Void) {
        remoteService.load { [weak self] result in
            guard let `self` = self else { return }
            self.dispatch {
                switch result {
                case .success:
                    completion(result)
                    
                case .failure:
                    self.localService.load(completion: completion)
                }
            }
        }
    }
    
    func dispatch(completion: @escaping () -> Void) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async(execute: completion)
        }
        
        completion()
    }
}
