//
//  ThirdViewController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/2.
//

import UIKit

class ThirdViewController: UIViewController {
    let customTransitioningDelegate = TransitioningDelegate()
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        transitioningDelegate = customTransitioningDelegate
        modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        customTransitioningDelegate.presentationController?.customDelegate = self
        var size = view.bounds.size
        size.height -= 40
        preferredContentSize = size
    }
}

extension ThirdViewController: PageSheetPresentationControllerDelegate {
    func shouldDismiss() -> Bool {
        return false
    }

    func didAttemptToDismiss() {
        let alert = UIAlertController(title: "Should dismiss", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
}
