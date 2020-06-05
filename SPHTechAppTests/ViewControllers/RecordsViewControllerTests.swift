//
//  RecordsViewControllerTests.swift
//  SPHTechAppTests
//
//  Created by Hoang Nguyen on 6/5/20.
//  Copyright © 2020 Hoang Nguyen. All rights reserved.
//

import XCTest
import RxSwift
@testable import SPHTechApp

class RecordsViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadData() {
        let (_, _, service) = makeSUT()
        XCTAssertEqual(service.dataRequestsCount, 0)
    }
    
    func test_viewDidLoad_loadsData() {
        var (sut, viewModel, service) = makeSUT()
        sut.bind(to: viewModel)
        XCTAssertEqual(service.dataRequestsCount, 1)
    }
    
    func test_userInitiatedsReload_loadsData() {
        var (sut, viewModel, service) = makeSUT()
        
        XCTAssertEqual(service.dataRequestsCount, 0)
        
        sut.bind(to: viewModel)
        
        XCTAssertEqual(service.dataRequestsCount, 1)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(service.dataRequestsCount, 2)
        
        sut.simulateUserInitiatedReload()
        XCTAssertEqual(service.dataRequestsCount, 3)
    }
    
    func test_loadingDataIndicator_isVisibleWhileLoadingData() {
        var (sut, viewModel, service) = makeSUT()
        sut.bind(to: viewModel)
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
        
        service.completeLoadData(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")
        
        sut.simulateUserInitiatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a load")
        
        service.completeLoadData(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user intiated loading completes with error")
    }
    
    func test_loadDataCompletion_rendersUISuccessfully() {
        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.1, quater: "2019-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.2, quater: "2019-Q2")
        let item3 = RecordItem(id: 3, volumeOfMobileData: 0.5, quater: "2020-Q1")
        let item4 = RecordItem(id: 4, volumeOfMobileData: 0.4, quater: "2020-Q2")
        
        var (sut, viewModel, service) = makeSUT()
        sut.bind(to: viewModel)
        assertThat(sut, isRendering: [])
        
        service.completeLoadData(with: [item1, item2])
        XCTAssertEqual(sut.numberOfRenderedRecordCells(), 1)
        assertThat(sut, isRendering: [item1, item2])
        
        
        sut.simulateUserInitiatedReload()
        service.completeLoadData(with: [item1, item2, item3, item4], at: 1)
        assertThat(sut, isRendering: [item1, item2, item3, item4])
    }
    
    func test_loadDataCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let item1 = RecordItem(id: 1, volumeOfMobileData: 0.1, quater: "2019-Q1")
        let item2 = RecordItem(id: 2, volumeOfMobileData: 0.2, quater: "2019-Q2")
        let item3 = RecordItem(id: 3, volumeOfMobileData: 0.5, quater: "2020-Q1")
        let item4 = RecordItem(id: 4, volumeOfMobileData: 0.4, quater: "2020-Q2")
        
        var (sut, viewModel, service) = makeSUT()
        sut.bind(to: viewModel)

        service.completeLoadData(with: [item1, item2, item3, item4], at: 0)
        assertThat(sut, isRendering: [item1, item2, item3, item4])

        sut.simulateUserInitiatedReload()
        service.completeLoadDataWithError(at: 1)
        assertThat(sut, isRendering: [item1, item2, item3, item4])
    }
    
    func test_showAlert() {
        let item1 = RecordItem(id: 3, volumeOfMobileData: 0.5, quater: "2020-Q1")
        let item2 = RecordItem(id: 4, volumeOfMobileData: 0.4, quater: "2020-Q2")
        let service = MobileDataServiceSpy()
        let viewModel = RecordsViewModel(service)

        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RecordsViewController")
        object_setClass(controller, MockRecordsViewController.self)
        var sut = controller as! MockRecordsViewController
        
        sut.bind(to: viewModel)
        
        service.completeLoadData(with: [item1, item2], at: 0)
        
        XCTAssertFalse(sut.isShownAlert)
        sut.simulateUserTapInfoButton(at: 0)
        
        XCTAssertTrue(sut.isShownAlert)
    }
    
    func assertThat(_ sut: RecordsViewController, isRendering records: [RecordItem], file: StaticString = #file, line: UInt = #line) {
        let annual = AnnualRecordItems(records: records)
        
        guard sut.numberOfRenderedRecordCells() == annual.annualRecords.count else {
            return XCTFail("Expected \(annual.annualRecords.count) items, got \(sut.numberOfRenderedRecordCells()) instead.", file: file, line: line)
        }

        annual.annualRecords.enumerated().forEach { index, article in
            assertThat(sut, hasViewConfiguredFor: article, at: index, file: file, line: line)
        }
    }

    func assertThat(_ sut: RecordsViewController, hasViewConfiguredFor record: AnnualRecordItem, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.recordCell(at: index)

        guard let cell = view as? RecordCell else {
            return XCTFail("Expected \(RecordCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        XCTAssertEqual(cell.yearLabel.text, "Year: \(record.year)")
        XCTAssertEqual(cell.volumeLabel.text, "Volume: \(record.volume)")
        XCTAssertEqual(cell.infoButton.isHidden, !record.isDecrease)
    }
    
    //MARK: - Helpers
    func makeSUT() -> (sut: RecordsViewController, viewModel: RecordsViewModel, service: MobileDataServiceSpy) {
        let service = MobileDataServiceSpy()
        let viewModel = RecordsViewModel(service)
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RecordsViewController") as! RecordsViewController
        
        return (viewController, viewModel, service)
    }
    
    class MobileDataServiceSpy: MobileDataService {
        
        private var dataRequests = [(MobileDataService.Result) -> ()]()
        
        var dataRequestsCount: Int {
            return dataRequests.count
        }
        
        func load(completion: @escaping (MobileDataService.Result) -> Void) {
            dataRequests.append(completion)
        }
        
        func completeLoadData(with article: [RecordItem] = [], at index: Int = 0) {
            dataRequests[index](.success(article))
        }
        
        func completeLoadDataWithError(at index: Int = 0) {
            let error = NSError(domain: "an error", code: 0)
            dataRequests[index](.failure(error))
        }
    }
    
    class MockRecordsViewController: RecordsViewController {
    
        var isShownAlert = false
        override func showAlert(_ item: AnnualRecordItem) {
            isShownAlert = true
            super.showAlert(item)
        }
    }
}

private extension RecordsViewController {
    func simulateUserInitiatedReload() {
        self.viewModel.inputs.load.onNext(true)
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl.isRefreshing == true
    }
    
    func numberOfRenderedRecordCells() -> Int {
        return tableView.numberOfRows(inSection: 0)
    }
    
    func recordCell(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: 0)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    func simulateUserTapInfoButton(at row: Int) {
        if let cell = recordCell(at: row) as? RecordCell {
            cell.infoButton.sendActions(for: .touchUpInside)
        }
    }
}
