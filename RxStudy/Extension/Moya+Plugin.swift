//
//  Moya+Plugin.swift
//  RxStudy
//
//  Created by season on 2021/5/25.
//  Copyright © 2021 season. All rights reserved.
//

import Foundation

import Moya
import MBProgressHUD

class RequestLoadingPlugin: PluginType {
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        print("prepare")
        var mRequest = request
        mRequest.timeoutInterval = 20
        return mRequest
    }
    
    func willSend(_ request: RequestType, target: TargetType) {
        print("开始请求")
        DispatchQueue.main.async {
            MBProgressHUD.beginLoading()
        }
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        print("结束请求")
        // 关闭loading
        DispatchQueue.main.async {
            MBProgressHUD.stopLoading()
        }
        
        switch result {
        case .success(let response):
            let json = try? response.mapJSON(failsOnEmptyData: false)
            if response.statusCode == 200 {
                print(json)
            }else {
                DispatchQueue.main.async {
                    // 进行统一弹窗
                }
            }
            
            
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        return result
    }
}

extension MBProgressHUD {
    static var keyWindow: UIWindow {
        return UIApplication.shared.keyWindow!
    }
    
    /// 为啥不用start,因为容易混淆
    static func beginLoading() {
        MBProgressHUD.showAdded(to:keyWindow , animated: true)
    }
    
    static func stopLoading() {
        MBProgressHUD.hide(for: keyWindow, animated: true)
    }
    
    static func showText(_ text: String) {
        
    }
}