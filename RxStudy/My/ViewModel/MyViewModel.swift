//
//  MyViewModel.swift
//  RxStudy
//
//  Created by season on 2021/6/16.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Moya

class MyViewModel: BaseViewModel {
    let logoutDataSource: [My] = [.ranking, .openSource, .login]
    
    let loginDataSource: [My] = [.ranking, .openSource, .myCoin, .myCollect, .logout]
    
    let currentDataSource = BehaviorRelay<[My]>(value: [])
    
    let myCoin = BehaviorRelay<MyCoin?>(value: nil)
    
    private let disposeBag: DisposeBag
    
    init(disposeBag: DisposeBag) {
        self.disposeBag = disposeBag
        super.init()
        
        AccountManager.shared.isLogin.subscribe(onNext: { [weak self] isLogin in
            guard let self = self else { return }
            
            print("\(self.className)收到了关于登录状态的值")
            
            self.currentDataSource.accept(isLogin ? self.loginDataSource : self.logoutDataSource)
            
            if isLogin {
               
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    let result = self.getMyCoin()
                    result.map{ $0.data }
                        /// 去掉其中为nil的值
                        .compactMap{ $0 }
                        .subscribe(onSuccess: { data in
                            self.myCoin.accept(data)
                        }, onError: { error in
                            guard let _ = error as? MoyaError else { return }
                            self.networkError.onNext(())
                        })
                        .disposed(by: disposeBag)
                }
            }
        }).disposed(by: disposeBag)
    }
}

extension MyViewModel {
    func getMyCoin() -> Single<BaseModel<MyCoin>> {
        return myProvider.rx.request(MyService.userCoinInfo)
            .map(BaseModel<MyCoin>.self)
            /// 转为Observable
            .asObservable().asSingle()
    }
    
    func logout() -> Single<BaseModel<String>> {
        return accountProvider.rx.request(AccountService.logout)
            .map(BaseModel<String>.self)
            /// 转为Observable
            .asObservable().asSingle()
    }
}