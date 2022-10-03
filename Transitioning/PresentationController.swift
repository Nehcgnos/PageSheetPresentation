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

    var isInteractive = true
    var transitionDuration: TimeInterval = 0.5
    let interactor = UIPercentDrivenInteractiveTransition()
    var isPresenting = true
    var maskColor = UIColor.black.withAlphaComponent(0.5)
    private weak var scrollView: UIScrollView?

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        isInteractive = true
        interactor.timingCurve = UISpringTimingParameters(dampingRatio: 0.91, initialVelocity: CGVector(dx: 1, dy: 1))
        interactor.completionSpeed = 1
        interactor.wantsInteractiveStart = true
    }

    deinit {
        print(#function)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = containerView else { return }
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
        guard isInteractive else {
            return nil
        }
        return interactor
    }

    @objc func handle(pan gesture: UIPanGestureRecognizer) {
        let deltaY = gesture.translation(in: containerView).y
        let percent = deltaY / presentedViewController.view.frame.height
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
            if percent > 0.3 {
                interactor.finish()
            } else {
                interactor.cancel()
            }
        default:
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
        let d: CGFloat = 3
        let timingParameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: d, dy: d))
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

protocol PageSheetPresentationControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func shouldDismiss() -> Bool
    func didAttemptToDismiss()
}

extension PageSheetPresentationControllerDelegate {
    func shouldDismiss() -> Bool {
        return true
    }

    func didAttemptToDismiss() {}
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
        return scrollView.contentOffset.y == 0
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRequireFailureOf _: UIGestureRecognizer) -> Bool {
        return false
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailBy _: UIGestureRecognizer) -> Bool {
        return false
    }
}
