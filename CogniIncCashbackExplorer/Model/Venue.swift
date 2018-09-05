//
//  Venue.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import Foundation
import MapKit

class Venue: NSObject, MKAnnotation {
    let name: String
    let city: String
    let cashback: Float
    let lat: Double
    let long: Double
    let createdBy: User?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        var subtitle = "\(cashback)%, \(city)"
        if let user = createdBy {
            subtitle = subtitle + ", created By \(user.name)"
        }
        return subtitle
    }
    
    init(name: String, city: String, cashback: Float, lat: Double, long: Double, createdBy: User? = nil) {
        self.name = name
        self.city = city
        self.cashback = cashback
        self.lat = lat
        self.long = long
        self.createdBy = createdBy
    }
    
    static func parse(dict: [String: Any]) -> Venue? {
        let name = dict["name"] as? String
        let city = dict["city"] as? String
        let cashback = dict["cashback"] as? CGFloat
        let lat = dict["lat"] as? Double
        let long = dict["long"] as? Double
        
        //check mandatory fields
        guard let venueName = name,
            let venueCity = city,
            let venueCashback = cashback,
            let venueLat = lat,
            let venueLong = long else {
                return nil
                
        }
        
        var createdBy: User?
        if let userDict = dict["user"] as? [String: Any],
            let user = User.parse(dict: userDict) {
            createdBy = user
        }
        
        return Venue(name: venueName, city: venueCity, cashback: Float(venueCashback), lat: venueLat, long: venueLong, createdBy: createdBy)
        
    }
}
