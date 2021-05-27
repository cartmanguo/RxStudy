//
//  HomeController.swift
//  RxStudy
//
//  Created by season on 2021/5/25.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import NSObject_Rx
import SnapKit
import MJRefresh
import Kingfisher
import FSPagerView

/// 需要非常小心循环引用
class HomeController: BaseViewController {
    
    private lazy var tableView = UITableView(frame: .zero, style: .plain)
    
    var itmes: [Banner] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "积分排名"
        view.backgroundColor = .white
        setupUI()
    }
}

extension HomeController {
    private func setupUI() {
        
        //MARK:- tableView的设置
        
        /// 设置代理
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        tableView.estimatedRowHeight = 88
        
        /// 简单布局
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        /// 获取indexPath
        tableView.rx.itemSelected
            .bind { [weak self] (indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: false)
                print(indexPath)
            }
            .disposed(by: rx.disposeBag)
        
        
        /// 获取cell中的模型
        tableView.rx.modelSelected(Info.self)
            .subscribe { model in
            print("模型为:\(model)")
            }
            .disposed(by: rx.disposeBag)
        
        /// 同时获取indexPath和模型
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(Info.self))
            .bind { indexPath, model in
                
            }
            .disposed(by: rx.disposeBag)

        /// 设置头部刷新控件
        tableView.mj_header = MJRefreshNormalHeader()
        /// 设置尾部刷新控件
        tableView.mj_footer = MJRefreshBackNormalFooter()
                
        let viewModel = HomeViewModel(disposeBag: rx.disposeBag)

        tableView.mj_header?.rx.refreshAction
            .asDriver()
            .drive(onNext: {
                viewModel.inputs.loadData(actionType: .refresh)
                
            })
            .disposed(by: disposeBag)

        tableView.mj_footer?.rx.refreshAction
            .asDriver()
            .drive(onNext: {
                viewModel.inputs.loadData(actionType: .loadMore)
                
            })
            .disposed(by: disposeBag)

        // 绑定数据
        viewModel.outputs.dataSource
            .asDriver()
            .drive(tableView.rx.items) { [weak self] (tableView, row, info) in
                if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
                    self?.cellSetting(cell: cell, info: info)
                    return cell
                }else {
                    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
                    self?.cellSetting(cell: cell, info: info)
                    return cell
                }
            }
            .disposed(by: rx.disposeBag)
        
        
        viewModel.outputs.refreshStatusBind(to: tableView)?
            .disposed(by: disposeBag)
        
        //MARK:- 轮播图的设置,这一段基本上就典型的Cocoa代码了
        
        let pagerView = FSPagerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 16.0 * 9))
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        pagerView.automaticSlidingInterval = 3.0
        pagerView.isInfinite = true
        tableView.tableHeaderView = pagerView
        
        let pageControl = FSPageControl(frame: CGRect.zero)
        pageControl.numberOfPages = itmes.count
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pagerView.addSubview(pageControl)
        pagerView.bringSubviewToFront(pageControl)
        pageControl.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(pagerView)
            make.height.equalTo(40)
        }
        
        viewModel.outputs.banners.asDriver().drive { [weak self] models in
            self?.itmes = models
            pageControl.numberOfPages = models.count
            pagerView.reloadData()
        }.disposed(by: rx.disposeBag)


        tableView.mj_header?.beginRefreshing()
    }
    
    private func cellSetting(cell: UITableViewCell, info: Info) {
        cell.textLabel?.text = info.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = info.author
        cell.detailTextLabel?.textColor = .gray
//        if let imageString = info.envelopePic, let url = URL(string: imageString) {
//            cell.imageView?.kf.setImage(with: url)
//        }
    }
}

extension HomeController: FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return itmes.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        if let imagePath = itmes[index].imagePath, let url = URL(string: imagePath) {
            cell.imageView?.kf.setImage(with: url)
        }
        return cell
    }
}

extension HomeController: FSPagerViewDelegate {
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: false)
        let item = itmes[index]
        print("点击了轮播图的\(item)")
    }
    
    func pagerView(_ pagerView: FSPagerView, willDisplay cell: FSPagerViewCell, forItemAt index: Int) {
        guard let pageControl = pagerView.subviews.last as? FSPageControl else {
            return
        }
        pageControl.currentPage = index
    }
}

extension HomeController: UITableViewDelegate {}