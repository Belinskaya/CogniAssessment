//
//  NewVenueViewController.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit

protocol NewVenueViewControllerDelegate: class {
    func newVenueWasAdded(_ venue: Venue)
}

class NewVenueViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var longTextField: UITextField!
    @IBOutlet weak var cashbackTextField: UITextField!
    
    @IBOutlet weak var nameErrorLabel: UILabel!
    @IBOutlet weak var cityErrorLabel: UILabel!
    @IBOutlet weak var latErrorLabel: UILabel!
    @IBOutlet weak var longErrorLabel: UILabel!
    @IBOutlet weak var cashbackErrorLabel: UILabel!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var acivityIndicator: UIActivityIndicatorView!
    
    weak var delegate: NewVenueViewControllerDelegate?
    
    private var allTextFields: [UITextField]?
    
    private var firstResponder: UITextField? {
        return allTextFields?.filter({ textField -> Bool in
            return textField.isFirstResponder
        }).first
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        nameTextField.delegate = self
        cityTextField.delegate = self
        latTextField.delegate = self
        
        let leftButtonDescription: TextFieldAccessoryButtonDescription = (title: "+/-", target: self, action: #selector(leftAccessoryButtonTapped))
        let rightButtonDescription: TextFieldAccessoryButtonDescription = (title: "Done", target: self, action: #selector(rightAccessoryButtonTapped))
        
        latTextField.addDoneButton(leftButton: leftButtonDescription, rightButton: rightButtonDescription)
        longTextField.delegate = self
        longTextField.addDoneButton(leftButton: leftButtonDescription, rightButton:  rightButtonDescription)
        cashbackTextField.delegate = self
        cashbackTextField.addDoneButton(leftButton: nil, rightButton: rightButtonDescription)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Use my Location", style: .plain, target: self, action: #selector(useMyLocationTapped))
        
        acivityIndicator.isHidden = true
        
        allTextFields = [nameTextField, cityTextField, latTextField, longTextField, cashbackTextField]
    }
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        guard let name = nameTextField.text,
            let city = cityTextField.text,
            let latString = latTextField.text,
            let lat = Double(latString),
            let longString = longTextField.text,
            let long = Double(longString),
            let cashbackText = cashbackTextField.text,
            let cashback = Float(cashbackText) else { return }
        
        hideAllErrorLabels()
        submitButton.isHidden = true
        acivityIndicator.isHidden = false
        acivityIndicator.startAnimating()
        let newVenue = Venue(name: name, city: city, cashback: cashback, lat: lat, long: long)
        SessionManager.shared.addNewVenue(newVenue) { result in
            self.acivityIndicator.stopAnimating()
            self.acivityIndicator.isHidden = true
            self.submitButton.isHidden = false
            switch result {
            case .sussess(data: let venues):
                self.delegate?.newVenueWasAdded(venues?.first ?? newVenue)
            case .failure(error: let errors):
                self.showError(errors)
            }
        }
    }
    
    @objc private func rightAccessoryButtonTapped() {
        guard let firstResponder = firstResponder else { return }
        
        if firstResponder == latTextField {
            longTextField.becomeFirstResponder()
        } else if firstResponder == longTextField {
            cashbackTextField.becomeFirstResponder()
        } else if firstResponder == cashbackTextField {
            cashbackTextField.resignFirstResponder()
        }
    }
    
    @objc private func leftAccessoryButtonTapped() {
        guard let firstResponder = firstResponder,
            let textValue = firstResponder.text,
            let number = Double(textValue) else { return }
        firstResponder.text = String(number * -1)
    }
    
    @objc private func useMyLocationTapped() {
        guard let userLocation = SessionManager.shared.locationManager.location else { return }
        
        latTextField.text = String(userLocation.coordinate.latitude)
        longTextField.text = String(userLocation.coordinate.longitude)
    }
    
    private func showError(_ errors: [CashbackExplorerErrors]) {
        for error in errors {
            switch error {
            case .invalidName:
                nameErrorLabel.isHidden = false
            case .invalidCity:
                cityErrorLabel.isHidden = false
            case .invalidLong:
                longErrorLabel.isHidden = false
            case .invalidLat:
                latErrorLabel.isHidden = false
            case .invalidCashback:
                cashbackErrorLabel.isHidden = false
            default:
                showGenericError()
                //do not show more than 1 generic error
                break
            }
        }
    }
    
    private func hideAllErrorLabels() {
        nameErrorLabel.isHidden = true
        cityErrorLabel.isHidden = true
        longErrorLabel.isHidden = true
        latErrorLabel.isHidden = true
        cashbackErrorLabel.isHidden = true
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let name = nameTextField.text,
            let city = cityTextField.text,
            let lat = latTextField.text,
            let long = longTextField.text,
            let cashback = cashbackTextField.text,
            city.count > 0 && name.count > 0 && lat.count > 0 && long.count > 0 && cashback.count > 0 {
            submitButton.isEnabled = true
        } else {
            submitButton.isEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            cityTextField.becomeFirstResponder()
        } else if textField == cityTextField {
            latTextField.becomeFirstResponder()
        } else if textField == latTextField {
            longTextField.becomeFirstResponder()
        } else if textField == longTextField {
            cashbackTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
