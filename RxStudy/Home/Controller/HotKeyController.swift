//
//  HotKeyController.swift
//  RxStudy
//
//  Created by season on 2021/5/28.
//  Copyright © 2021 season. All rights reserved.
//

import UIKit

class HotKeyController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .playAndroidBg
        
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width - 40, height: 34))
        textField.textColor = .black
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 17
        textField.layer.masksToBounds = true
        textField.backgroundColor = .white
        textField.returnKeyType = .search
        textField.font = UIFont.systemFont(ofSize: 15)
        
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.leftView = emptyView
        textField.rightView = emptyView
        textField.leftViewMode = .always
        textField.rightViewMode = .always
        
        /// 状态可以组合
        textField.rx.controlEvent([.editingDidEndOnExit])
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.pushToSearchResultController(keyword: textField.text!)
            }).disposed(by: rx.disposeBag)
        
        navigationItem.titleView = textField
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
        navigationItem.rightBarButtonItem?.rx.tap.subscribe({ [weak self] _ in
            self?.pushToSearchResultController(keyword: textField.text!)
        }).disposed(by: rx.disposeBag)
        
        let searchValid = textField.rx.text.orEmpty
                .map { $0.isNotEmpty }
                .share(replay: 1)
        
        searchValid.bind(to: navigationItem.rightBarButtonItem!.rx.isEnabled).disposed(by: rx.disposeBag)
        
        let viewModel = HotKeyViewModel()
        
        viewModel.inputs.loadData()
        
        viewModel.outputs.dataSource
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self ] hotKeys in
                self?.tagLayout(hotKeys: hotKeys)
        }).disposed(by: rx.disposeBag)
        
        /*
        /// 这么写会循环引用
        viewModel.outputs.dataSource
            .bind(onNext: tagLayout)
            .disposed(by: rx.disposeBag)
        /// 为了避免循环引用,需要将bind(onNext:(Element) -> Void)这个写进行下的改造才行
        viewModel.outputs.dataSource
            .bind { [weak self] in self?.tagLayout(hotKeys: $0) }
            .disposed(by: rx.disposeBag)
        */
        
        viewModel.outputs.networkError
            .bind(to: rx.networkError)
            .disposed(by: rx.disposeBag)
        
        errorRetry
            .bind(onNext: viewModel.inputs.loadData)
            .disposed(by: rx.disposeBag)
    }
    
    private func tagLayout(hotKeys: [HotKey]) {
        let textPadding: CGFloat = 10.0
        let texts = hotKeys.map { $0.name }.compactMap { $0 }
        
        let tuples = texts.map { title -> (UIButton, CGFloat) in
            let button = UIButton(type: .custom)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 4
            button.layer.masksToBounds = true
            
            
            /// 原始版本
            button.rx.tap.subscribe { [weak self] _ in
                self?.pushToSearchResultController(keyword: title)
            }.disposed(by: rx.disposeBag)
            
            /* 这种写法会导致循环引用
            /// 赋值为一个闭包传入,便于理解的版本
            let function = pushToSearchResultController
            button.rx.tap
                .map { title }
                .bind(onNext: function)
                .disposed(by: rx.disposeBag)
            
             
            /// 直接将函数当作闭包直接传入
            button.rx.tap
                .map { title }
                .bind(onNext: pushToSearchResultController)
                .disposed(by: rx.disposeBag)
             */
            
            let width = title.size(withFont: (button.titleLabel?.font)!).width + textPadding * 2
            return (button, width)
        }
        
        let buttons = tuples.map { $0.0 }
        let textWidths = tuples.map { $0.1 }
        
        
        let _ = tuples.map {
            self.view.addSubview($0.0)
        }
        
        // verticalSpacing   每个view之间的垂直距离
        // horizontalSpacing 每个view之间的水平距离
        // maxWidth 是整个布局的最大宽度，需要事前传入，比如 self.view.bounds.size.width - 40
        // textWidth 是每个view的宽度，也需事前计算好
        // itemHeight 每个view的高度
        // edgeInset 整个布局的 上下左右边距，默认为 .zero
        // topConstrainView 整个布局之上的view, 从topConstrainView.snp.bottom开始计算，
        // 比如,传入上面的label,则从 label.snp.bottom + edgeInset.top 开始排列， 默认为nil, 此时布局从 superview.snp.top + edgeInset.top 开始计算
        buttons.snp.distributeDetermineWidthViews(verticalSpacing: 20,
                                                  horizontalSpacing: 10,
                                                  maxWidth: view.bounds.size.width - 40,
                                                  determineWidths: textWidths,
                                                  itemHeight: 30,
                                                  edgeInset: UIEdgeInsets(top: 20 + kTopMargin,
                                                                          left: 16,
                                                                          bottom: 0,
                                                                          right: 16))
    }
    
    private func pushToSearchResultController(keyword: String) {
        let vc = SearcResultController(keyword: keyword)
        navigationController?.pushViewController(vc, animated: true)
    }
}
