//
//  BaseTableViewController.swift
//  RxStudy
//
//  Created by season on 2021/5/31.
//  Copyright © 2021 season. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

import MJRefresh
import DZNEmptyDataSet

class BaseTableViewController: BaseViewController {
    
    lazy var tableView = UITableView(frame: .zero, style: .plain)
    
    let emptyDataSetButtonTap = PublishSubject<Void>()
    
    let isEmpty = BehaviorRelay(value: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        
        /// 设置tableFooterView
        tableView.tableFooterView = UIView()
        
        /// 设置代理
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        
        /// 简单布局
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        /// 设置头部刷新控件
        tableView.mj_header = MJRefreshNormalHeader()
        /// 设置尾部刷新控件
        tableView.mj_footer = MJRefreshBackNormalFooter()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        emptyDataSetButtonTap.subscribe { [weak self] _ in
            self?.tableView.mj_header?.beginRefreshing()
        }.disposed(by: rx.disposeBag)
    }

}

extension BaseTableViewController: UITableViewDelegate {}

extension BaseTableViewController: DZNEmptyDataSetSource {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "暂无数据")
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "尝试点击刷新获取数据")
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return .clear
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -60
    }
}

extension BaseTableViewController: DZNEmptyDataSetDelegate {

    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return isEmpty.value
    }

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap view: UIView!) {
        emptyDataSetButtonTap.onNext(())
    }
}