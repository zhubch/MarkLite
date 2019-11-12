//
//  PreviewViewController.swift
//  Markdown
//
//  Created by zhubch on 2017/6/28.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class PreviewViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {
    
    let webView = UIWebView(frame: CGRect())
    let scrollView = UIScrollView(frame: CGRect())
    
    var offset: CGFloat = 0 {
        didSet {
            var y = offset * (scrollView.contentSize.height - scrollView.h)
            if y > contentHeight - scrollView.h  {
                y = contentHeight - scrollView.h
            }
            if y < 0 {
                y = 0
            }
            scrollView.contentOffset = CGPoint(x: 0,y: y)
        }
    }
    
    var contentHeight: CGFloat = 0 {
        didSet {
            scrollView.contentSize = CGSize(width: 0,height: contentHeight)
            webView.frame = CGRect(x: 0, y: 0, w: scrollView.w, h: contentHeight)
        }
    }
    
    var keyboardHeight: CGFloat = windowHeight {
        didSet {
            let h = max(windowHeight - keyboardHeight - bottomInset, 0)
            UIView.animate(withDuration: 0.5, animations: {
                self.scrollView.h = self.view.size.height - h
            })
        }
    }
    
    var shouldRefresh = false
    
    var timer: Timer?

    var html: String = "" {
        didSet {
            if html != oldValue {
                shouldRefresh = true
            }
        }
    }
    
    var url: URL?
    
    var didScrollHandler: ((CGFloat)->Void)?
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        webView.scalesPageToFit = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 2
        view.addSubview(scrollView)
        scrollView.addSubview(webView)
        
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }

        view.setBackgroundColor(.background)
                
        timer = Timer.runThisEvery(seconds: 0.5, handler: { [weak self] _ in
            if self?.shouldRefresh ?? false {
                self?.refresh()
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        shouldRefresh = true
        let h = max(windowHeight - keyboardHeight - bottomInset, 0)
        scrollView.frame = CGRect(x: 0, y: 0, w: view.w, h: view.h - h)
        contentHeight = scrollView.h
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let size = change?[NSKeyValueChangeKey.newKey] as? CGSize {
            if fabs(self.contentHeight - size.height) > 10 {
                self.contentHeight = size.height
            }
        }
    }
    
    func refresh() {
        webView.stopLoading()
        webView.loadHTMLString(self.html, baseURL: url)
        shouldRefresh = false
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        print("webViewDidStartLoad")
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("webViewDidFinishLoad")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let pan = scrollView.panGestureRecognizer
//        let velocity = pan.velocity(in: scrollView).y
//        if velocity < -10 {
//            self.navigationController?.setNavigationBarHidden(true, animated: true)
//        } else if velocity > 10 {
//            self.navigationController?.setNavigationBarHidden(false, animated: true)
//        }
        
        let offset = scrollView.contentOffset.y
        if scrollView.contentSize.height - scrollView.h <= 0 {
            didScrollHandler?(0)
        } else {
            didScrollHandler?(offset / (scrollView.contentSize.height - scrollView.h))
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return webView
    }
    
    deinit {
        timer?.invalidate()
        webView.loadHTMLString("", baseURL: nil)
        webView.scrollView.removeObserver(self, forKeyPath: "contentSize")
        removeNotificationObserver()
        print("deinit web_vc")
    }
}
