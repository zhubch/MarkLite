//
//  WebViewController.swift
//  Markdown
//
//  Created by 朱炳程 on 2019/7/19.
//  Copyright © 2019 zhubch. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    let webView = WKWebView(frame: CGRect())
    
    var urlString = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        self.view.addSubview(webView)
        
        guard let url = URL(string: urlString) else { return }
        self.webView.load(URLRequest(url: url))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action:#selector(close))
        
        ActivityIndicator.show()
    }
    
    @objc func close() {
        impactIfAllow()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = self.view.bounds;
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ActivityIndicator.dismiss()
        webView .evaluateJavaScript("document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '140%'") { (_, _) in
            
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ActivityIndicator.dismiss()
    }
}
