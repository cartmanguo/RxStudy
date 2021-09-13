//
//  MyCollectionController.swift
//  RxStudy
//
//  Created by season on 2021/6/17.
//  Copyright © 2021 season. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import NSObject_Rx
import SnapKit
import MJRefresh

class MyCollectionController: BaseTableViewController {
    
    private var isEdited = BehaviorRelay(value: false)
    
    private lazy var edit = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightBarButtonItemAction))
    
    private lazy var done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonItemAction))

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        
        title = "我的收藏"
        
        navigationItem.rightBarButtonItem = edit
        
        isEdited.bind(to: tableView.rx.isShowEdit).disposed(by: rx.disposeBag)
        
        /// 获取cell中的模型
        tableView.rx.modelSelected(Info.self)
            .subscribe(onNext: { [weak self] model in
                guard let self = self else { return }
                self.pushToWebViewController(webLoadInfo: model)
            })
            .disposed(by: rx.disposeBag)
                
        let viewModel = MyCollectionViewModel()

        tableView.mj_header?.rx.refresh
            .asDriver()
            .drive(onNext: {
                viewModel.inputs.loadData(actionType: .refresh)
                
            })
            .disposed(by: rx.disposeBag)

        tableView.mj_footer?.rx.refresh
            .asDriver()
            .drive(onNext: {
                viewModel.inputs.loadData(actionType: .loadMore)
                
            })
            .disposed(by: rx.disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: { indexPath in
                viewModel.inputs.unCollectAction(indexPath: indexPath)
            })
            .disposed(by: rx.disposeBag)

        
        errorRetry.subscribe { _ in
            viewModel.inputs.loadData(actionType: .refresh)
        }.disposed(by: rx.disposeBag)

        /// 绑定数据
        viewModel.outputs.dataSource
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items) { (tableView, row, info) in
                if let cell = tableView.dequeueReusableCell(withIdentifier: InfoViewCell.className) as? InfoViewCell {
                    cell.info = info
                    return cell
                }else {
                    let cell = InfoViewCell(style: .subtitle, reuseIdentifier: InfoViewCell.className)
                    cell.info = info
                    return cell
                }
            }
            .disposed(by: rx.disposeBag)
        
        viewModel.outputs.dataSource.map { $0.count == 0 }.bind(to: isEmpty).disposed(by: rx.disposeBag)
        
        viewModel.outputs.networkError.bind(to: rx.networkError).disposed(by: rx.disposeBag)
        
        /// 下拉与上拉状态绑定到tableView
        viewModel.outputs.refreshSubject
            .bind(to: tableView.rx.refreshAction)
            .disposed(by: rx.disposeBag)
    }

}

extension MyCollectionController {
    @objc
    private func rightBarButtonItemAction() {
        let value = !isEdited.value
        isEdited.accept(value)
        self.navigationItem.rightBarButtonItem = value ? done : edit
    }
}

extension Reactive where Base: UITableView {
    var isShowEdit: Binder<Bool> {
        return Binder(base) { base, isEdit in
            base.setEditing(isEdit, animated: true)
        }
    }
}
