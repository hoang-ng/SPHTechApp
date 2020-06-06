//
//  SceneDelegate.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private lazy var httpClient: HTTPClient = {
        URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    }()
    
    private lazy var store: MobileDataStore = {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return CodableMobileDataStore(storeURL: cachesDirectory.appendingPathComponent("MobileData.store"))
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let remoteURL = URL(string: "https://data.gov.sg/api/action/datastore_search?resource_id=a807b7ab-6cad-4aa6-87d0-e283a7353a0f")!
        let localMobileDataService = LocalMobileDataService(store: store)
        let remoteMobileDataService = RemoteMobileDataService(remoteURL, client: httpClient)
        let cache = MobileDataServiceCacheDecorator(decoratee: remoteMobileDataService, cache: localMobileDataService)
        let service = MobileDataServiceComposite(remoteService: cache, localService: localMobileDataService)
        
        window?.rootViewController = UINavigationController(
            rootViewController: RecordsUIComposer.composeWith(service))
        
        window?.makeKeyAndVisible()
    }


}

