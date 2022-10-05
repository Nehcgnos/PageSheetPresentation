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

    func animationController(forPresented _: UIViewController, presenting _: UIViewController,
                             source _: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        presentationController
    }

    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationController
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?,
                                source _: UIViewController) -> UIPresentationController?
    {
        let controller = PageSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            config: config
        )
        presentationController = controller
        return controller
    }
}
