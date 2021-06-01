//
//  AccountManager.swift
//  RxStudy
//
//  Created by season on 2021/6/1.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import NSObject_Rx
import MBProgressHUD

final class AccountManager {
    static let shared = AccountManager()
    
    private(set) var isLogin = BehaviorRelay(value: false)
    
    private let disposeBag = DisposeBag()
        
    private(set) var accountInfo: AccountInfo?
    
    var cookieHeaderValue: String {
        if let username = accountInfo?.username, let password = accountInfo?.password {
          return "loginUserName=\(username);loginUserPassword=\(password)";
        } else {
          return ""
        }
      }
    
    private init() {}
    
    func saveLoginUsernameAndPassword(info: AccountInfo?, username: String, password: String) {
        isLogin.accept(true)
        accountInfo = info
        accountInfo?.username = username
        accountInfo?.password = password
        
        UserDefaults.standard.setValue(username, forKey: kUsername)
        UserDefaults.standard.setValue(password, forKey: kPassword)
    }
    
    func clearAccountInfo() {
        isLogin.accept(false)
        accountInfo = nil
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.value(forKey: kUsername) as? String
    }
    
    func getPassword() -> String? {
        return UserDefaults.standard.value(forKey: kPassword) as? String
    }
    
    func autoLogin() {
        if !isLogin.value {
            guard let username = getUsername(), let password = getPassword() else {
                return
            }
            login(username: username, password: password)
        }
    }
    
    func login(username: String, password: String) {
        accountProvider.rx.request(AccountService.login(username, password))
            .map(BaseModel<AccountInfo>.self)
            /// 转为Observable
            .asObservable().asSingle().subscribe { baseModel in
                if baseModel.errorCode == 0 {
                    AccountManager.shared.saveLoginUsernameAndPassword(info: baseModel.data, username: username, password: password)
                    DispatchQueue.main.async {
                        MBProgressHUD.showText("登录成功")
                    }
                }
            } onError: { _ in
                
            }.disposed(by: disposeBag)
    }
}

extension AccountManager: HasDisposeBag {}
