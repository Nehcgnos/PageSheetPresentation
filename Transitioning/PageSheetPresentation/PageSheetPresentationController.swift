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

    private weak var customDelegate: CustomPresentationControllerDelegate?
    private let config: TransitionConfig
    private var state: State = .presenting
    private weak var scrollView: UIScrollView?
    private let dimmingView = UIView()
    private var presentedViewFrame: CGRect = .zero
    private var shouldDismiss = true

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?,
         config: TransitionConfig)
    {
        self.config = config
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        customDelegate = config.delegate
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = containerView else { return }
        state = .presenting
        dimmingView.alpha = 0
        dimmingView.backgroundColor = config.maskColor
        dimmingView.frame = containerView.bounds
        if config.dismissOnTapWhiteSpace {
            dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView)))
        }
        containerView.insertSubview(dimmingView, at: 0)
        presentingViewController.beginAppearanceTransition(false, animated: true)

        for subview in presentedViewController.view.subviews {
            guard let scrollView = subview as? UIScrollView else { continue }
            self.scrollView = scrollView
            break
        }

        if config.isInteractionEnabled {
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

        presentingViewController.beginAppearanceTransition(false, animated: true)
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
                offset = 3 * deltaY / (3.5 + 0.02 * deltaY)
                actualPercent = offset / presentedViewController.view.frame.height
            }
            panChanged(with: actualPercent, offset: offset)
        case .cancelled:
            scrollView?.bounces = true
            restoreViewFrame(with: config.duration)
        case .ended:
            scrollView?.bounces = true
            let velocity = gesture.velocity(in: containerView).y
            guard shouldDismiss else {
                if percent > 0 {
                    let offset = presentedViewController.view.frame.minY - presentedViewFrame.minY
                    let actualPercent = offset / presentedViewFrame.height
                    customDelegate?.customPresentationControllerDidAttemptToDismiss(self)
                    restoreViewFrame(with: config.duration * (1 - actualPercent))
                }
                return
            }
            if percent > 0.4 || velocity > 900 {
                presentedViewController.dismiss(animated: true)
            } else {
                restoreViewFrame(with: config.duration)
            }
        default:
            restoreViewFrame(with: config.duration)
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
        config.duration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        startAnimation(using: context)
    }

    private func startAnimation(using context: UIViewControllerContextTransitioning) {
        let containerView = context.containerView
        UIView.animate(
            withDuration: config.duration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            if self.state == .presenting {
                guard let toView = context.view(forKey: .to) else { return }
                toView.frame.origin.y = containerView.frame.height - toView.frame.height
                if let transform = self.config.fromViewTransform {
                    context.viewController(forKey: .from)?.view.transform = transform
                }
            } else {
                guard let fromView = context.view(forKey: .from) else { return }
                fromView.frame.origin.y = containerView.frame.height
                context.viewController(forKey: .to)?.view.transform = .identity
                if let _ = self.config.fromViewTransform {
                    context.viewController(forKey: .from)?.view.transform = .identity
                }
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
        return scrollView.contentOffset.y == 0
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
}
