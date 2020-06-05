//
//  RecordCell.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RecordCell: UITableViewCell {
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    
    // MARK: ViewModel
    var viewModel: RecordCellModelType! {
        didSet {
            configureUI()
        }
    }
    
    private var disposeBag = DisposeBag()
    
    // MARK: Overrides

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()
    }
    
    private func configureUI() {
        yearLabel.text = viewModel.outputs.year
        volumeLabel.text = viewModel.outputs.volume
        infoButton.isHidden = !viewModel.outputs.isDecrease
        
        infoButton.rx.tap.bind(to: viewModel.inputs.infoTapAction).disposed(by: disposeBag)
    }
}
