//
//  RecordCellModel.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation
import RxSwift

protocol RecordCellModelInput {
    var infoTapAction: PublishSubject<Void> { get }
}

protocol RecordCellModelOutput {
    var year: String { get }
    var volume: String { get }
    var isDecrease: Bool { get }
    var showDecreaseAlert: Observable<AnnualRecordItem> { get }
}

protocol RecordCellModelType {
    var inputs: RecordCellModelInput { get }
    var outputs: RecordCellModelOutput { get }
}

final class RecordCellModel: RecordCellModelType, RecordCellModelInput, RecordCellModelOutput {
    // MARK: Inputs & Outputs
    var inputs: RecordCellModelInput { return self }
    var outputs: RecordCellModelOutput { return self }
    
    // MARK: Input
    var infoTapAction = PublishSubject<Void>()
    
    // MARK: Output
    lazy var year: String = {
        return "Year: \(record.year)"
    }()
    
    lazy var volume: String = {
        return "Volume: \(record.volume)"
    }()
    
    lazy var isDecrease: Bool = {
        return record.isDecrease
    }()
    
    var showDecreaseAlert: Observable<AnnualRecordItem>
    
    // MARK: Private
    private let record: AnnualRecordItem
    
    // MARK: Init
    init(record: AnnualRecordItem) {
        self.record = record
        showDecreaseAlert = infoTapAction.map { _ -> AnnualRecordItem in
            return record
        }
    }
}
