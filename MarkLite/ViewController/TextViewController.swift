//
//  TextViewController.swift
//  Markdown
//
//  Created by zhubch on 2017/6/28.
//  Copyright © 2017年 zhubch. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import EZSwiftExtensions

class TextViewController: UIViewController {

    @IBOutlet weak var editView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var seperator: UIView!

    @IBOutlet weak var bottomSpace: NSLayoutConstraint!

    var textChangedHandler: ((String)->Void)?
    var offsetChangedHandler: ((CGFloat)->Void)?

    let bag = DisposeBag()
    var manager = MarkdownHighlightManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRx()

        addNotificationObserver(Notification.Name.UIKeyboardWillChangeFrame.rawValue, selector: #selector(keyboardWillChange(_:)))
        
        editView.textContainer.lineBreakMode = .byCharWrapping
        view.setBackgroundColor(.background)
        bottomView.setTintColor(.primary)
        countLabel.setTextColor(.secondary)
    }
    
    func setupRx() {
        
        Configure.shared.isAssistBarEnabled.asObservable().subscribe(onNext: { [unowned self](enable) in
            if enable {
                let assistBar = AssistKeyboardBar()
                assistBar.textView = self.editView
                assistBar.viewController = self
                self.editView.inputAccessoryView = assistBar
            } else {
                self.editView.inputAccessoryView = nil
            }
        }).disposed(by: bag)
        
        Configure.shared.isLandscape.asObservable().map{!$0}.bind(to: seperator.rx.isHidden).disposed(by: bag)
        
        Configure.shared.theme.asObservable().subscribe(onNext: { [weak self] _ in
            self?.manager = MarkdownHighlightManager()
            self?.textChanged()
        }).disposed(by: bag)
        
        editView.rx.didChange.subscribe { [weak self] _ in
            self?.textChanged()
            }.disposed(by: bag)
        
        editView.rx.text.map{($0?.length ?? 0) > 0}
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: bag)
        
        editView.rx.contentOffset.map{$0.y}.subscribe(onNext: { [weak self] (offset) in
            guard let this = self else { return }
            this.offsetChangedHandler?(offset / this.editView.contentSize.height)
        }).disposed(by: bag)
    }
    
    func textChanged() {
        DispatchQueue.main.async {
            self.redoButton.isEnabled = self.editView.undoManager?.canRedo ?? false
            self.undoButton.isEnabled = self.editView.undoManager?.canUndo ?? false
        }

        textChangedHandler?(editView.text)
        countLabel.text = editView.text.length.toString + " " + /"Characters"
        if editView.markedTextRange != nil {
            return
        }
        manager.highlight(editView.text) { [weak self] (attrText) in
            self?.didHighlight(attrText: attrText)  
        }
    }
    
    func didHighlight(attrText: NSAttributedString) {
        editView.isScrollEnabled = false
        let selectedRange = editView.selectedRange
        editView.attributedText = attrText
        editView.selectedRange = selectedRange
        editView.isScrollEnabled = true
    }
    
    @IBAction func undo(_ sender: UIButton) {
        editView.undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: UIButton) {
        editView.undoManager?.redo()
    }
    
    @objc func keyboardWillChange(_ noti: NSNotification) {
        guard let frame = (noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        bottomSpace.constant = max(self.view.h - frame.y + 10,0)
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.editView.scrollRangeToVisible(self.editView.selectedRange)
        }
    }
    
    deinit {
        removeNotificationObserver()
        print("deinit text_vc")
    }
    
}
