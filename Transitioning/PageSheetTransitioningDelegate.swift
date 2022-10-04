//
//  PageSheetTransitioningDelegate.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/3.
//

import UIKit

struct TransitionConfig {
    let maskColor: UIColor?
    let duration: TimeInterval
    let isInteractionEnabled: Bool
    let dismissOnTapWhiteSpace: Bool
    let fromViewTransform: CGAffineTransform?
    weak var delegate: CustomPresentationControllerDelegate?
}

class PageSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    private let config: TransitionConfig
    
    weak var presentationController: PageSheetPresentationController?
    
    init(config: TransitionConfig) {
        self.config = config
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = PageSheetPresentationController(presentedViewController: presented, presenting: presenting, config: config)
        presentationController = controller
        return controller
    }
}
