//
//  RecordsUIComposer.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import UIKit

final class RecordsUIComposer {

    static func composeWith(_ mobileDataService: MobileDataService) -> RecordsViewController {
        let viewModel = RecordsViewModel(mobileDataService)
        let viewController = makeRecordsViewController(viewModel: viewModel)
        return viewController
    }
    
    private static func makeRecordsViewController(viewModel: RecordsViewModelType) -> RecordsViewController {
        var viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RecordsViewController") as! RecordsViewController
        viewController.bind(to: viewModel)
        return viewController
    }
}
