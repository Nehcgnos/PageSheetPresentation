//
//  SecondViewController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/1.
//

import UIKit

class SecondViewController: UIViewController {
    private let customTransitioningDelegate = TransitioningDelegate()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        transitioningDelegate = customTransitioningDelegate
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: view.frame.width, height: 500)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        print(String(describing: self), #function)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print(String(describing: self), #function)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        print(String(describing: self), #function)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        print(String(describing: self), #function)
    }
    
    deinit {
        print(#function)
    }
}
