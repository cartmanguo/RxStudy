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
    
    private let isEditedRelay = BehaviorRelay(value: false)
    
    /// 没有使用
    private lazy var edit = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(rightBarButtonItemAction))
    
    /// 没有使用
    private lazy var done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonItemAction))

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        
        title = "我的收藏"
        
        /// 是否在编辑与tableView的编辑状态绑定
        isEditedRelay.bind(to: tableView.rx.isShowEdit).disposed(by: rx.disposeBag)
        
        MyCollectionController.done.rx.tap
            .map { [weak self] in
                guard let self else {
                    return true
                }
                return !self.isEditedRelay.value
            }
            .bind(to: isEditedRelay)
            .disposed(by: rx.disposeBag)
        
        MyCollectionController.edit.rx.tap
            .map { [weak self] in
                guard let self else {
                    return false
                }
                return !self.isEditedRelay.value
            }
            .bind(to: isEditedRelay)
            .disposed(by: rx.disposeBag)
        
        isEditedRelay
            .map { $0 ? MyCollectionController.done : MyCollectionController.edit }
            .bind(to: navigationItem.rx.rightBarButtonItem)
            .disposed(by: rx.disposeBag)
        
        /// 点击cell,获取cell中的模型
        tableView.rx.modelSelected(Info.self)
            .subscribe(onNext: { [weak self] model in
                guard let self else { return }
                self.pushToWebViewController(webLoadInfo: model)
            })
            .disposed(by: rx.disposeBag)
                
        let viewModel = MyCollectionViewModel()

        /// 下拉刷新
        /// Bug:下拉刷新会出发上拉刷新操作
        /// 问题在viewModel中对于
        /// 下拉做赋值运算self.dataSource.accept(datas),但是其他界面都是好的,就这一个出异常,还真是奇怪
        tableView.mj_header?.rx.refresh
            .map { ScrollViewActionType.refresh }
            .bind(onNext: viewModel.inputs.loadData)
            .disposed(by: rx.disposeBag)

        /// 上拉加载更多
        tableView.mj_footer?.rx.refresh
            .map { ScrollViewActionType.loadMore }
            .bind(onNext: viewModel.inputs.loadData)
            .disposed(by: rx.disposeBag)
        
        /// cell删除
        tableView.rx.itemDeleted
            .bind(onNext: viewModel.inputs.unCollectAction)
            .disposed(by: rx.disposeBag)

        /// 错误重试
        errorRetry
            .map { ScrollViewActionType.refresh }
            .bind(onNext: viewModel.inputs.loadData)
            .disposed(by: rx.disposeBag)

        /// 绑定数据
        viewModel.outputs.dataSource
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items) { (tableView, row, info) in

                let cell = tableView.dequeueReusableCell(withIdentifier: InfoViewCell.className) as! InfoViewCell 
                cell.info = info
                return cell
            }
            .disposed(by: rx.disposeBag)
        
        /// 数据源是否为空绑定
        viewModel.outputs.dataSource
            .map { $0.isEmpty }
            .bind(to: isEmptyRelay)
            .disposed(by: rx.disposeBag)
        
        /// 请求错误绑定
        viewModel.outputs.networkError
            .bind(to: rx.networkError)
            .disposed(by: rx.disposeBag)
        
        /// 下拉与上拉状态绑定到tableView
        viewModel.outputs.refreshSubject
            .bind(to: tableView.rx.refreshAction)
            .disposed(by: rx.disposeBag)
    }

}

extension MyCollectionController {
    
    /// 传统的右侧的点击事件,没有使用
    @objc
    private func rightBarButtonItemAction() {
        let value = !isEditedRelay.value
        isEditedRelay.accept(value)
        self.navigationItem.rightBarButtonItem = value ? done : edit
    }
}

extension MyCollectionController {
    private static let edit = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
    
    private static let done = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
}

extension MyCollectionController {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

extension Reactive where Base: UITableView {
    var isShowEdit: Binder<Bool> {
        return Binder(base) { base, isEdit in
            base.setEditing(isEdit, animated: true)
        }
    }
}

extension Reactive where Base: UINavigationItem {
    var rightBarButtonItem: Binder<UIBarButtonItem> {
        return Binder(base) { base, item in
            base.rightBarButtonItem = item
        }
    }
}
