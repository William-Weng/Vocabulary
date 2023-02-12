//
//  LicenseWebViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/2/12.
//

import UIKit
import WebKit

// MARK: - 資源說明頁
final class LicenseWebViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?._tabBarHidden(true, animated: true)
    }

    @IBAction func goBack(_ sender: UIBarButtonItem) {
        
        guard let webView = view as? WKWebView else { return }
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: UIBarButtonItem) {
        
        guard let webView = view as? WKWebView else { return }
        webView.goForward()
    }
}

// MARK: - 小工具
extension LicenseWebViewController {
    
    func initSetting() {
        
        let webView = WKWebView._build(delegate: nil, frame: view.bounds, contentInsetAdjustmentBehavior: .always)
        self.view = webView
        
        let url = Bundle.main.url(forResource: "License", withExtension: "html")
        _ = webView._load(urlString: url?.absoluteString, timeoutInterval: 60)
    }
}
