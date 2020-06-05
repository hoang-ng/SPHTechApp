//
//  RecordsViewModel.swift
//  SPHTechApp
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import Foundation
import RxSwift

protocol RecordsViewModelInput {
    var load: BehaviorSubject<Bool> { get }
}

protocol RecordsViewModelOutput {
    var title: String { get }
    var isLoading: Observable<Bool> { get }
    var recordCellModelTypes: Observable<[RecordCellModelType]> { get }
}

protocol RecordsViewModelType {
    var inputs: RecordsViewModelInput { get }
    var outputs: RecordsViewModelOutput { get }
}

class RecordsViewModel: RecordsViewModelType, RecordsViewModelInput, RecordsViewModelOutput {
    
    // MARK: Inputs & Outputs
    var inputs: RecordsViewModelInput { return self }
    var outputs: RecordsViewModelOutput { return self }
    
    // MARK: Input
    let load: BehaviorSubject<Bool>
    
    // MARK: Output
    let title = "Mobile Data Usage"
    let isLoading: Observable<Bool>
    let recordCellModelTypes: Observable<[RecordCellModelType]>
    
    // MARK: Private
    private let service: MobileDataService
    
    init(_ service: MobileDataService) {
        self.service = service
        
        let loadData = BehaviorSubject<Bool>(value: true)
        self.load = loadData
        self.isLoading = loadData
        
        let result = loadData.flatMap { isRefreshing -> Observable<Result<[RecordItem], Error>> in
            guard isRefreshing else { return .empty() }
            return Observable.create { observer -> Disposable in
                service.load { result in
                    observer.onNext(result)
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        }
        
        let requestData = result.map { result -> [AnnualRecordItem]? in
            loadData.onNext(false)
            switch result {
            case let .success(records):
                let annualData = AnnualRecordItems(records: records)
                return annualData.annualRecords
            case .failure(_):
                return nil
            }
        }
        .compactMap { $0 }
        
        recordCellModelTypes = requestData.map({ record -> [RecordCellModelType] in
            record.map { RecordCellModel(record: $0) }
        })
    }
}
