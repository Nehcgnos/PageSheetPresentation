//
//  TransitioningDelegate.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/2.
//

import UIKit

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var transitionDuration: TimeInterval = 0.52
    var interactionEnabled = true
    var fromViewTransform: CGAffineTransform?
    
    weak var presentationController: PresentationController?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.isPresenting = true
        return presentationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController?.isPresenting = false
        return presentationController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        presentationController?.interactorIfNeeded()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = PresentationController(presentedViewController: presented, presenting: presenting)
        controller.transitionDuration = transitionDuration
        controller.interactionEnabled = true
        presentationController = controller
        return controller
    }
    
    deinit {
        print(#function)
    }
}
