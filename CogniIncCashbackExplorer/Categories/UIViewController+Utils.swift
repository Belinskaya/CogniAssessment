//
//  UIViewController+Utils.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showGenericError(title: String = "Something went wrong", message: String = "Please try again in a few minutes.", completionHandler: (()->Void)? = nil) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // TODO: add completionHandler here
        let okAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
        alertVC.addAction(okAction)
        present(alertVC, animated: true)
    }
    
    func performSegue(withIdentifier identifier: StringRepresentable, sender: Any? = nil) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
    
    func hideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapDetected))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func tapDetected() {
        view.endEditing(true)
    }
    
}


