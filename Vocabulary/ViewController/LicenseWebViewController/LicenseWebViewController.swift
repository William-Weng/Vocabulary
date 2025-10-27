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
    
    @IBOutlet weak var goBackItem: UIBarButtonItem!
    @IBOutlet weak var goForwardItem: UIBarButtonItem!
    
    weak var othersViewDelegate: OthersViewDelegate?
    
    private var progressView: UIProgressView!
    private var observation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        othersViewDelegate?.tabBarHidden(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        othersViewDelegate?.tabBarHidden(false)
    }
    
    @IBAction func goBack(_ sender: UIBarButtonItem) {
        guard let webView = view as? WKWebView else { return }
        webView.goBack()
    }
    
    @IBAction func goForward(_ sender: UIBarButtonItem) {
        guard let webView = view as? WKWebView else { return }
        webView.goForward()
    }
    
    deinit {
        othersViewDelegate = nil
        observation = nil
        myPrint("\(Self.self) deinit")
    }
}

// MARK: - WKNavigationDelegate, WKUIDelegate
extension LicenseWebViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { goItemSetting(with: webView) }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView._disableUserSelectAndTouch { result in myPrint(result) }
        webView._disableUserScale{ result in myPrint(result) }
    }
}

// MARK: - 小工具
private extension LicenseWebViewController {
    
    /// WebView初始化設定
    func initSetting() {
        
        let webView = WKWebView._build(delegate: self, frame: view.bounds, contentInsetAdjustmentBehavior: .automatic)
        let url = Bundle.main.url(forResource: "README.html", withExtension: nil)

        self.view = webView        
        _ = webView._load(urlString: url?.absoluteString, timeoutInterval: 60)
        
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        fixContentInset(with: webView)
        estimatedProgress(with: webView)
    }
    
    /// 修正WebView滿版問題 => contentInsetAdjustmentBehavior
    /// - Parameter webView: WKWebView
    func fixContentInset(with webView: WKWebView) {
        
        if let navigationBarHeight = navigationController?.navigationBar._rootView()?.frame.height {
            webView.scrollView.contentInset = UIEdgeInsets(top: navigationBarHeight, left: 0, bottom: 0, right: 0)
        }
    }
    
    /// 設定上下頁按鍵狀態
    /// - Parameter webView: WKWebView
    func goItemSetting(with webView: WKWebView) {
        goBackItem.isEnabled = webView.canGoBack
        goForwardItem.isEnabled = webView.canGoForward
    }
    
    /// [網址讀取進度條設定](https://juejin.cn/post/6894106901186330632)
    /// - Parameter webView: WKWebView
    func estimatedProgress(with webView: WKWebView) {
        
        let navigationBarHeight = navigationController?.navigationBar._rootView()?.frame.height ?? 0
        let thickness: CGFloat = 5.0
        
        observation = webView._estimatedProgress(with: navigationBarHeight - thickness * 0.5, thickness: thickness)
    }
}
