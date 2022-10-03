//
//  PageSheetPresentationController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/3.
//

import UIKit

protocol CustomPresentationControllerDelegate: NSObject {
    func customPresentationControllerShouldDismiss() -> Bool
    func customPresentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController)
}

extension CustomPresentationControllerDelegate {
    func customPresentationControllerShouldDismiss() -> Bool {
        false
    }

    func customPresentationControllerDidAttemptToDismiss(_: UIPresentationController) {}
}

class PageSheetPresentationController: UIPresentationController {
    enum State {
        case presenting
        case dismissing
    }

    var isInteractionEnabled = true
    var transitionDuration: TimeInterval = 0.52
    var state: State = .presenting
    var maskColor = UIColor.black.withAlphaComponent(0.5)
    weak var customDelegate: CustomPresentationControllerDelegate?

    private weak var scrollView: UIScrollView?
    private let dimmingView = UIView()
    private var presentedViewFrame: CGRect = .zero
    private var shouldDismiss = true

    deinit {
        print(#function)
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = containerView else { return }
        state = .presenting
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

        if isInteractionEnabled {
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
        state = .dismissing
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

extension PageSheetPresentationController {
    @objc func didTapDimmingView() {
        if let delegate = customDelegate, !delegate.customPresentationControllerShouldDismiss() {
            return
        }
        presentedViewController.dismiss(animated: true)
    }

    @objc func handle(pan gesture: UIPanGestureRecognizer) {
        let deltaY = gesture.translation(in: containerView).y
        let percent = min(deltaY / presentedViewController.view.frame.height, 1)
        switch gesture.state {
        case .began:
            shouldDismiss = customDelegate?.customPresentationControllerShouldDismiss() ?? true
            scrollView?.bounces = false
            presentedViewFrame = presentedViewController.view.frame
        case .changed:
            scrollView?.bounces = percent < 0
            guard percent >= 0 else { return }
            var offset = deltaY
            var actualPercent = percent
            if !shouldDismiss {
                let y = deltaY
                let max = 0.25 * presentedViewFrame.height
                offset = 2.6 * max / (1 + 4338.47 / pow(y, 1.14791))
                print(offset)
                actualPercent = offset / presentedViewController.view.frame.height
            }
            panChanged(with: actualPercent, offset: offset)
        case .cancelled:
            scrollView?.bounces = true
            restoreViewFrame(with: transitionDuration)
        case .ended:
            scrollView?.bounces = true
            let velocity = gesture.velocity(in: containerView).y
            guard shouldDismiss else {
                if percent > 0 {
                    let offset = presentedViewController.view.frame.minY - presentedViewFrame.minY
                    let actualPercent = offset / presentedViewFrame.height
                    customDelegate?.customPresentationControllerDidAttemptToDismiss(self)
                    restoreViewFrame(with: transitionDuration * (1 - actualPercent))
                }
                return
            }
            let duration = transitionDuration * min(1 - percent, 1)
            if percent > 0.4 || velocity > 900 {
                transitionDuration = duration
                presentedViewController.dismiss(animated: true)
            } else {
                restoreViewFrame(with: duration)
            }
        default:
            restoreViewFrame(with: transitionDuration)
        }
    }
    
    private func panChanged(with percent: CGFloat, offset: CGFloat) {
        var frame = presentedViewFrame
        frame.origin.y += offset
        presentedViewController.view.frame = frame
        dimmingView.alpha = 1 - percent
    }
    
    private func restoreViewFrame(with duration: TimeInterval) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: [.allowUserInteraction, .curveEaseInOut],
            animations: {
                self.dimmingView.alpha = 1
                self.presentedViewController.view.frame = self.presentedViewFrame
            },
            completion: nil
        )
    }
}

extension PageSheetPresentationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        transitionDuration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        startAnimation(using: context)
    }

    private func startAnimation(using context: UIViewControllerContextTransitioning) {
        let containerView = context.containerView
        UIView.animate(
            withDuration: transitionDuration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            if self.state == .presenting {
                guard let toView = context.view(forKey: .to) else { return }
                toView.frame.origin.y = containerView.frame.height - toView.frame.height
            } else {
                guard let fromView = context.view(forKey: .from) else { return }
                fromView.frame.origin.y = containerView.frame.height
            }
        } completion: { finished in
            guard finished else { return }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
}

extension PageSheetPresentationController: UIGestureRecognizerDelegate {
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
