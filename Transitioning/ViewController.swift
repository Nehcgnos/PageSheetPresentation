//
//  ViewController.swift
//  Transitioning
//
//  Created by Nehcgnos on 2022/10/1.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(String(describing: self), #function)
    }

    @IBAction func system() {
        present(isCustomized: false)
    }

    @IBAction func custom() {
        present(isCustomized: true)
    }

    private func present(isCustomized: Bool) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let thirdViewController = sb.instantiateViewController(withIdentifier: "third")
        if #available(iOS 13.0, *) {
            thirdViewController.modalPresentationStyle = isCustomized ? .custom : .automatic
        }
        present(thirdViewController, animated: true)
    }
}
