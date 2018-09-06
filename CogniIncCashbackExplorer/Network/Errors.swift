//
//  Errors.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import Foundation

typealias LoginCompletionHadler = (LoginResult) -> Void
typealias CashbackExplorerCompletionHadler = (CashbackExplorerResult) -> Void

enum LoginActionType: String {
    case signin = "/users"
    case update = "/login"
}

enum LoginResult {
    case sussess
    case failure(error: [CashbackExplorerErrors])
}

enum CashbackExplorerResult {
    case sussess(data: [Venue]?)
    case failure(error: [CashbackExplorerErrors])
}

enum CashbackExplorerErrors: Error {
    case duplicateUser
    case invalidCashback
    case invalidCity
    case invalidEmail
    case invalidName
    case invalidLat
    case invalidLong
    case venuesNotFound
    case unknown
}
