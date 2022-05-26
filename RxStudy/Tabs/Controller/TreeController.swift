//
//  TreeController.swift
//  RxStudy
//
//  Created by season on 2021/5/27.
//  Copyright © 2021 season. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import NSObject_Rx
import RxDataSources
import SnapKit

/// 使用tableView配合section即可完成需求
class TreeController: BaseTableViewController {
    
    private let type: TagType
    
    init(type: TagType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

extension TreeController {
    private func setupUI() {
        title = type.title
        
        tableView.mj_header = nil
        tableView.mj_footer = nil
            
        /// 获取cell中的模型
        tableView.rx.modelSelected(Tab.self)
            .subscribe(onNext: { [weak self] tab in
                guard let self = self else { return }
                let vc = SingleTabListController(type: self.type, tab: tab)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: rx.disposeBag)
                
        let viewModel = TreeViewModel(type: type)

        viewModel.inputs.loadData()

        /// 绑定数据
        viewModel.outputs.dataSource
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] tabs in
                self?.tableViewSectionAndCellConfig(tabs: tabs)
            })
            .disposed(by: rx.disposeBag)
        
        /// 重写
        emptyDataSetButtonTap.subscribe { _ in
            viewModel.inputs.loadData()
        }.disposed(by: rx.disposeBag)
        
        viewModel.outputs.networkError
            .bind(to: rx.networkError)
            .disposed(by: rx.disposeBag)
        
        errorRetry.subscribe { _ in
            viewModel.inputs.loadData()
        }.disposed(by: rx.disposeBag)
    }
    
    private func tableViewSectionAndCellConfig(tabs: [Tab]) {
        guard tabs.count > 0 else {
            return
        }
        
        /// 这种带有section的tableView,不能通过一级菜单确定是否有数据,需要将二维数组进行降维打击
        let children = tabs.map { $0.children }.compactMap { $0 }
        let deepChildren = children.flatMap{ $0 }.map { $0.children }.compactMap { $0 }.flatMap { $0 }
        Observable.just(deepChildren).map { $0.isEmpty }
            .bind(to: isEmptyRelay)
            .disposed(by: rx.disposeBag)
        
        let sectionModels = tabs.map { tab in
            return SectionModel(model: tab, items: tab.children ?? [])
        }

        let items = Observable.just(sectionModels)

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Tab, Tab>>(
            configureCell: { (ds, tv, indexPath, element) in
                
                let cell = tv.dequeueReusableCell(withIdentifier: UITableViewCell.className)!
                cell.textLabel?.text = ds.sectionModels[indexPath.section].model.children?[indexPath.row].name
                cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
                cell.accessoryType = .disclosureIndicator
                return cell
            
        },
            titleForHeaderInSection: { ds, index in
                return ds.sectionModels[index].model.name
        })

        //绑定单元格数据
        items.bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }
}
