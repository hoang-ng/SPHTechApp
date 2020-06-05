//
//  RecordsViewController.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RecordsViewController: UIViewController, BindableType {

    // MARK: ViewModel
    var viewModel: RecordsViewModelType!
    
    @IBOutlet var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    // MARK: Private
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureRefreshControl()
    }
    
    // MARK: BindableType
    func bindViewModel() {
        let inputs = viewModel.inputs
        let outputs = viewModel.outputs
        
        self.title = outputs.title
        refreshControl.rx.controlEvent(.valueChanged).map { _ -> Bool in
            return true
        }.bind(to: inputs.load)
            .disposed(by: disposeBag)
        
        outputs.isLoading.bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        outputs.recordCellModelTypes
            .bind(to: tableView.rx.items(cellIdentifier: "RecordCell", cellType: RecordCell.self)) { [weak self] _, recordCellModel, cell in
                guard let `self` = self else { return }
                cell.viewModel = recordCellModel
                recordCellModel.outputs.showDecreaseAlert.subscribe(onNext: { item in
                    self.showAlert(item)
                }).disposed(by: self.disposeBag)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: UI
    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    private func configureRefreshControl() {
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
    }

    func showAlert(_ item: AnnualRecordItem) {
        let alert = UIAlertController(title: "SPHTech", message: "Quarter in a year \(item.year) demonstrates a decrease in volume data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
