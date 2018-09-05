//
//  User.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import Foundation

struct User {
    let userId: UUID
    let name: String
    let email: String
    
    var key: String {
        return name + "_" + email
    }
    
    init(name: String, email: String, userId: UUID? = nil) {
        self.name = name
        self.email = email
        self.userId = userId ?? UUID()
    }
    
    static func parse(dict: [String: Any]) -> User? {
        guard let name = dict["name"] as? String,
            let email = dict["email"] as? String else { return nil }
        
        var userUUID: UUID?
        if let uuidString = dict["uuid"] as? String {
            userUUID = UUID(uuidString: uuidString)
        }
        return User(name: name, email: email, userId: userUUID)
    }
}
