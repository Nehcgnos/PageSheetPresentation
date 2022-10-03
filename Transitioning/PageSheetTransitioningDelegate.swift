//
//  PageSheetTransitioningDelegate.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/3.
//

import UIKit

struct TransitionConfig {
    let maskColor: UIColor?
    let isInteractionEnabled: Bool
    let dismissOnTapWhiteSpace: Bool
    let duration: TimeInterval
    let fromViewTransform: CGAffineTransform?
    weak var delegate: CustomPresentationControllerDelegate?
}

class PageSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var transitionDuration: TimeInterval = 0.52
    
    var isInteractionEnabled = true
    
    weak var delegate: CustomPresentationControllerDelegate? {
        didSet {
            presentationController?.customDelegate = delegate
        }
    }
    
    weak var presentationController: PageSheetPresentationController?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = PageSheetPresentationController(presentedViewController: presented, presenting: presenting)
        controller.transitionDuration = transitionDuration
        controller.isInteractionEnabled = isInteractionEnabled
        controller.customDelegate = delegate
        presentationController = controller
        return controller
    }
    
    deinit {
        print(#function)
    }
}
