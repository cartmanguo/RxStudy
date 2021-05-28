//
//  HotKeyViewModel.swift
//  RxStudy
//
//  Created by season on 2021/5/28.
//  Copyright © 2021 season. All rights reserved.
//

import RxSwift
import RxCocoa
import Moya

class HotKeyViewModel: BaseViewModel {
    
    private let disposeBag: DisposeBag
    
    init(disposeBag: DisposeBag) {
        self.disposeBag = disposeBag
    }
    
    /// outputs
    let dataSource = BehaviorRelay<[HotKey]>(value: [])
    
    // inputs
    func loadData() {
        requestData()
            .map{ $0.data }
        /// 去掉其中为nil的值
            .compactMap{ $0 }
        .drive(onNext: { items in
            self.dataSource.accept(items)
        })
        .disposed(by: disposeBag)
    }
}

//MARK:- 网络请求
private extension HotKeyViewModel {
    func requestData() -> Driver<BaseModel<[HotKey]>> {
        let result = homeProvider.rx.request(HomeService.hotKey)
            .map(BaseModel<[HotKey]>.self)
            /// 转为Observable
            .asDriver(onErrorDriveWith: Driver.empty())
        
        return result
    }
}
