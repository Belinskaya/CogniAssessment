//
//  UITextView+Utils.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit

typealias TextFieldAccessoryButtonDescription = (title: String, target: Any, action: Selector)

extension UITextField {
    func addDoneButton(leftButton: TextFieldAccessoryButtonDescription?, rightButton: TextFieldAccessoryButtonDescription?) {
        guard leftButton != nil || rightButton != nil else { return }
        
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        var items = [UIBarButtonItem]()
        if let leftButton = leftButton {
            items.append(UIBarButtonItem(title: leftButton.title, style: .plain, target: leftButton.target, action: leftButton.action))
        }
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil))
        if let rightButton = rightButton {
            items.append(UIBarButtonItem(title: rightButton.title, style: .plain, target: rightButton.target, action: rightButton.action))
        }
        toolbar.items = items
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
}
