//
//  SignInViewController.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var invalidNameLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var invalidEmailError: UILabel!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        activityIndicator.isHidden = true
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        guard let name = nameTextField.text, let email = emailTextField.text else { return }
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        SessionManager.shared.singIn(with: User(name: name, email: email)) { (result) in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            switch result {
            case .sussess:
                self.performSegue(withIdentifier: Segues.showVenues, sender: nil)
            case .failure(error: let loginError):
                self.showError(for: loginError)
            }
        }
    }
    
    private func showError(for loginErrors: [CashbackExplorerErrors]) {
        if let loginError = loginErrors.first {
            switch loginError {
            case .invalidEmail:
                invalidEmailError.isHidden = false
            case .invalidName:
                invalidNameLabel.text = Constants.ErrorMessages.invalidUserNameTitle
                invalidNameLabel.isHidden = false
            case .duplicateUser:
                invalidNameLabel.isHidden = false
                invalidNameLabel.text = Constants.ErrorMessages.duplicateUserTitle
            default:
                showGenericError()
            }
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let name = nameTextField.text, let email = emailTextField.text, email.count > 0 && name.count > 0 {
            signinButton.isEnabled = true
        } else {
            signinButton.isEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
