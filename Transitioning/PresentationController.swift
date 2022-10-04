//
//  PresentationController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/2.
//

import UIKit

class PresentationController: UIPresentationController {
    var interactionEnabled = true {
        didSet {
            if !interactionEnabled {
                isInteractive = false
            }
        }
    }

    var isInteractive = false
    var transitionDuration: TimeInterval = 0.52
    let interactor = UIPercentDrivenInteractiveTransition()
    var isPresenting = true
    var maskColor = UIColor.black.withAlphaComponent(0.5)
    private weak var scrollView: UIScrollView?

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        interactor.timingCurve = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: 1, dy: 1))
        interactor.completionSpeed = 1
        interactor.wantsInteractiveStart = true
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = containerView else { return }
        isPresenting = true
        dimmingView.alpha = 0
        dimmingView.backgroundColor = maskColor
        dimmingView.frame = containerView.bounds
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView)))
        containerView.insertSubview(dimmingView, at: 0)
        presentingViewController.beginAppearanceTransition(false, animated: true)

        for subview in presentedViewController.view.subviews {
            guard let scrollView = subview as? UIScrollView else { continue }
            self.scrollView = scrollView
            break
        }

        if interactionEnabled {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handle(pan:)))
            panGesture.delegate = self
            presentedViewController.view.addGestureRecognizer(panGesture)
        }

        var preferredContentSize = presentedViewController.preferredContentSize
        if preferredContentSize.height.isZero {
            preferredContentSize = presentedViewController.view.frame.size
        }
        presentedViewController.view.frame.origin.y = containerView.frame.height
        presentedViewController.view.frame.size.height = preferredContentSize.height
        
        let bezierPath = UIBezierPath(
            roundedRect: presentedViewController.view.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 10, height: 10)
        )
        let mask = CAShapeLayer()
        mask.path = bezierPath.cgPath
        presentedViewController.view.layer.mask = mask
        
        containerView.addSubview(presentedViewController.view)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 1
        })
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        presentingViewController.endAppearanceTransition()
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        isPresenting = false
        presentingViewController.beginAppearanceTransition(true, animated: true)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            presentingViewController.endAppearanceTransition()
        }
    }
}

extension PresentationController {
    @objc func didTapDimmingView() {
        isInteractive = false
        presentedViewController.dismiss(animated: true)
    }

    func interactorIfNeeded() -> UIViewControllerInteractiveTransitioning? {
        guard interactionEnabled, isInteractive else {
            return nil
        }
        return interactor
    }

    @objc func handle(pan gesture: UIPanGestureRecognizer) {
        let deltaY = gesture.translation(in: containerView).y
        let percent = deltaY / presentedViewController.view.frame.height
        let velocity = gesture.velocity(in: containerView).y
        switch gesture.state {
        case .began:
            if !presentedViewController.isBeingDismissed {
                isInteractive = true
                presentedViewController.dismiss(animated: true)
            }
        case .changed:
            scrollView?.bounces = percent < 0
            interactor.update(percent)
        case .cancelled:
            scrollView?.bounces = true
            isInteractive = false
            interactor.cancel()
        case .ended:
            scrollView?.bounces = true
            isInteractive = false
            if percent > 0.5 || velocity > 900 {
                interactor.completionSpeed = (1 - velocity) * transitionDuration
                interactor.finish()
                print("finish", percent, velocity)
            } else {
                interactor.cancel()
                print("cancel", percent, velocity)
            }
        default:
            print("other", percent, velocity)
//            interactor.cancel()
            break
        }
    }
}

extension PresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        transitionDuration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: context).startAnimation()
    }

    func interruptibleAnimator(using context: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: 0, dy: 0))
        let animator = UIViewPropertyAnimator(duration: transitionDuration, timingParameters: timingParameters)
        animator.isUserInteractionEnabled = true
        animator.isInterruptible = true
        let containerView = context.containerView
        animator.addAnimations {
            if self.isPresenting {
                guard let toView = context.view(forKey: .to) else { return }
                toView.frame.origin.y = containerView.frame.height - toView.frame.height
            } else {
                guard let fromView = context.view(forKey: .from) else { return }
                fromView.frame.origin.y = containerView.frame.height
            }
        }
        animator.addCompletion { _ in
            context.completeTransition(!context.transitionWasCancelled)
        }
        return animator
    }
}

extension PresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard let scrollView = scrollView else {
            return true
        }
        let location = gesture.location(in: scrollView)
        guard scrollView.layer.contains(location) else {
            return true
        }
        return scrollView.contentOffset.y <= 0
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
}
