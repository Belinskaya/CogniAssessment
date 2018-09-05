//
//  Segues.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import Foundation

protocol StringRepresentable {
    var rawValue: String { get }
}

func == (lhs: String?, rhs: StringRepresentable?) -> Bool {
    return lhs == rhs?.rawValue
}

enum Segues: String, StringRepresentable {
    case showVenues = "showVenues"
    case addNewVenue = "addNewVenue"
    
}
