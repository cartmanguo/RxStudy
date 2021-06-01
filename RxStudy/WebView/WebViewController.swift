//
//  WebViewController.swift
//  H5OCR
//
//  Created by season on 2020/6/23.
//  Copyright © 2020 season. All rights reserved.
//

import UIKit
import WebKit

import MBProgressHUD
import MarqueeLabel

private let JSCallback = "JSCallback"

class WebViewController: BaseViewController {

    let webLoadInfo: WebLoadInfo
    let isFromBanner: Bool
    
    init(webLoadInfo: WebLoadInfo, isFromBanner: Bool) {
        self.webLoadInfo = webLoadInfo
        self.isFromBanner = isFromBanner
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.userContentController.add(WeakScriptMessageDelegate(scriptDelegate: self), name: JSCallback)
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI(){
        let lengthyLabel = MarqueeLabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - 100, height: 44), duration: 8.0, fadeLength: 10.0)
        var title = webLoadInfo.title
        lengthyLabel.textAlignment = .center
        lengthyLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        lengthyLabel.text = title?.filterHTML()
        navigationItem.titleView = lengthyLabel
        
        view.addSubview(webView)
        webView.navigationDelegate = self
        webView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        guard let link = webLoadInfo.link, let url = URL(string: link) else {
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        let toSafari = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        
        toSafari.rx.tap.subscribe { _ in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }
        }.disposed(by: rx.disposeBag)
        
        let refreshWeb = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
        refreshWeb.rx.tap.subscribe { _ in
            self.webView.reload()
        }.disposed(by: rx.disposeBag)
        
        navigationItem.rightBarButtonItems = [refreshWeb, toSafari]
    }
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: JSCallback)
    }
    
}

// MARK: - 协议类专门用来处理监听JavaScript方法从而调用原生方法，和WKUserContentController搭配使用
extension WebViewController: WKScriptMessageHandler {
    
    /// 原生界面监听JS运行,截取JS中的对应在userContentController注册过的方法
    ///
    /// - Parameters:
    ///   - userContentController: WKUserContentController
    ///   - message: WKScriptMessage 其中包含方法名称已经传递的参数,WKScriptMessage,其中body可以接收的类型是Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("方法名:\(message.name)")
        print("参数:\(message.body)")
        
        guard let msg = message.body as? String else { return }
        
        if msg.isEmpty {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        print("decidePolicyForUrl == \(navigationAction.request.url?.absoluteString ?? "unkown")")
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MBProgressHUD.beginLoading()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MBProgressHUD.stopLoading()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        MBProgressHUD.stopLoading()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        MBProgressHUD.stopLoading()
    }
}
