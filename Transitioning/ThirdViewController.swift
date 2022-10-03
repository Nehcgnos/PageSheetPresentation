//
//  ThirdViewController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/2.
//

import UIKit

class ThirdViewController: UIViewController {
    let customTransitioningDelegate = TransitioningDelegate()
    let pageSheetTransitioningDelegate = PageSheetTransitioningDelegate()
    private var shouldDismiss = true

    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        transitioningDelegate = customTransitioningDelegate
        pageSheetTransitioningDelegate.isInteractionEnabled = true
        pageSheetTransitioningDelegate.delegate = self
        transitioningDelegate = pageSheetTransitioningDelegate
        modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var size = view.bounds.size
        size.height *= 0.8
        preferredContentSize = size
        presentationController?.delegate = self
        transitionCoordinator?.animate(alongsideTransition: { _ in

        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(String(describing: self), #function)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(String(describing: self), #function)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(String(describing: self), #function)
    }
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        shouldDismiss = sender.isOn
    }
}

extension ThirdViewController: CustomPresentationControllerDelegate {
    func customPresentationControllerShouldDismiss() -> Bool {
        shouldDismiss
    }

    func customPresentationControllerDidAttemptToDismiss(_: UIPresentationController) {
        showAlert()
    }

    private func showAlert() {
        let alert = UIAlertController(title: "Should dismiss", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

extension ThirdViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_: UIPresentationController) {
        showAlert()
    }

    func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
        return false
    }
}

extension ThirdViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        10
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    }

    func collectionView(_: UICollectionView, didSelectItemAt _: IndexPath) {
        dismiss(animated: true)
    }
}
