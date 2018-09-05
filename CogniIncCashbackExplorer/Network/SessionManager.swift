//
//  SessionManager.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import Foundation
import Alamofire
import Locksmith
import MapKit

struct Keys {
    static let name = "name"
    static let city = "city"
    static let email = "email"
    static let lat = "lat"
    static let long = "long"
    static let cashback = "cashback"
    static let token = "Token"
    static let tokenCreationDate = "tokenCreationDate"
    static let errors = "errors"
    static let details = "details"
    static let venue = "venue"
    static let arrayOfVenues = "venues"
}

struct Constants {
    static let defaultCity = "New York"
    static let thirtyDays: Double = 60 * 60 * 24 * 30
    
    struct ErrorMessages {
        static let genericTitle = ""
        static let genericmessage = ""
        static let cantLocateTitle = "We can't detect your location"
        static let defaultCityMessage = "We will show New York area as a default location"
        static let duplicateUserTitle = "This user is already exists"
        static let invalidUserNameTitle = "nvalid Name: name should be at least 2 character long and no more than 20 characters"
    }
}

class SessionManager {
    static var shared = SessionManager()
    
    let locationManager = CLLocationManager()
    private let baseURL = "https://cashback-explorer-api.herokuapp.com"
    
    private var token: String?
    private(set) var venues = [Venue]()
    
    init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func bypass() {
        if let token = UserDefaults.standard.object(forKey: Keys.token) as? String {
            self.token = token
        }
    }
    
    func singIn(with user: User, completionHandler: ((LoginResult)->Void)? = nil) {
        if let tokenData = Locksmith.loadDataForUserAccount(userAccount: user.key),
            let savedToken = tokenData[Keys.token] as? String,
            let creationDate = tokenData[Keys.tokenCreationDate] as? Date {
            if Date().timeIntervalSince(creationDate) > Constants.thirtyDays {
                //update token
                update(token: savedToken, for: user, completionHandler: completionHandler)
                return
            }
            self.token = savedToken
            if let completionHandler = completionHandler {
                completionHandler(.sussess)
            }
            return
        }
        // new user
        createNewUser(user, completionHandler: completionHandler)
    }
    
    private func createNewUser(_ user: User, completionHandler: ((LoginResult)->Void)? = nil) {
        let body: Parameters = [Keys.name: user.name, Keys.email: user.email]
        Alamofire.request(baseURL + "/users", method: .post, parameters: body, encoding: JSONEncoding.default, headers: nil).responseJSON { response in
            guard response.response?.statusCode == 201 else {
                var error: CashbackExplorerErrors = .unknown
                if case let Result.success(json) = response.result {
                    error = self.parseUserError(in: json)
                }
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [error]))
                }
                return
            }
            if self.saveToken(from: response.response, withKey: user.key) {
                if let completionHandler = completionHandler {
                    completionHandler(.sussess)
                }
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
            }
        }
    }
    
    private func update(token: String, for user: User, completionHandler: ((LoginResult)->Void)? = nil) {
        let body: Parameters = [Keys.name: user.name, Keys.email: user.email]
        let headers: HTTPHeaders = [Keys.token: token]
        print(body)
        Alamofire.request(baseURL + "/login", method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).responseString { response in
            guard response.response?.statusCode == 202 else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
                return
            }
            
            if self.saveToken(from: response.response, withKey: user.key) {
                if let completionHandler = completionHandler {
                    completionHandler(.sussess)
                }
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
            }
        }
    }
    
    func addNewVenue(_ venue: Venue, completionHandler: ((CashbackExplorerResult)->Void)? = nil) {
        guard let token = token else {
            if let completionHandler = completionHandler {
                completionHandler(.failure(error: [.unknown]))
            }
            return
        }
        
        let body: Parameters = [Keys.name: venue.name, Keys.city: venue.city, Keys.lat: venue.lat, Keys.long: venue.long, Keys.cashback: venue.cashback]
        let headers: HTTPHeaders = [Keys.token: token]
        Alamofire.request(baseURL + "/venues", method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            guard response.response?.statusCode == 201 else {
                var errors: [CashbackExplorerErrors] = [.unknown]
                if case let Result.success(json) = response.result {
                    errors = self.parseVenueError(in: json)
                }
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: errors))
                }
                return
            }
            if case let Result.success(json) = response.result,
                let responseDict = json as? [String: Any],
                let venueDict = responseDict[Keys.venue] as? [String: Any],
                let venue = Venue.parse(dict: venueDict) {
                self.venues.append(venue)
                if let completionHandler = completionHandler {
                    completionHandler(.sussess(data: [venue]))
                }
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
            }
        }
    }
    
    func getListOfVenues(for city: String = Constants.defaultCity, completionHandler: ((CashbackExplorerResult)->Void)? = nil) {
        guard let token = token else {
            if let completionHandler = completionHandler {
                completionHandler(.failure(error: [.unknown]))
            }
            return
        }
        let headers: HTTPHeaders = [Keys.token: token]
        let parameters: Parameters = [Keys.city: city]
        Alamofire.request(baseURL + "/venues", method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers).responseJSON { response in
            guard response.response?.statusCode == 200 else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
                return
            }
            if case let Result.success(json) = response.result,
                let responseDict = json as? [String: Any],
                let venueDict = responseDict[Keys.arrayOfVenues] as? [Any] {
                let venues = venueDict.map({ (entry) -> [String: Any]? in
                    return entry as? [String: Any]
                }).compactMap { $0 }.map({ venueDict -> Venue? in
                    return Venue.parse(dict: venueDict)
                }).compactMap { $0 }
                
                self.venues = venues
                if let completionHandler = completionHandler {
                    completionHandler(.sussess(data: venues))
                }
                
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.failure(error: [.unknown]))
                }
            }
        }
    }
    
    private func saveToken(from response: HTTPURLResponse?, withKey key: String) -> Bool {
        guard let response = response,
            let responseToken = response.allHeaderFields[Keys.token] as? String else { return false }
        
        self.token = responseToken
        
        let tokenData: [String: Any] = [Keys.token: "responseToken", Keys.tokenCreationDate: Date()]
        try? Locksmith.saveData(data: tokenData, forUserAccount: key)
        
        return true
    }
    
    private func parseUserError(in json: Any) -> CashbackExplorerErrors {
        guard let dictOfErrors = json as? [String: Any] else { return .unknown }
        
        if let errorDetails = dictOfErrors[Keys.errors] as? [String: Any] {
            if let _ = errorDetails[Keys.name] {
                return .invalidName
            } else if let _ = errorDetails[Keys.email] {
                return .invalidEmail
            }
        }
        if let detail = dictOfErrors[Keys.details] as? String, detail.contains("already exists") {
            return .duplicateUser
        }
        return .unknown
    }
    
    private func parseVenueError(in json: Any) -> [CashbackExplorerErrors] {
        guard let dictOfErrors = json as? [String: Any] else { return [.unknown] }
        
        var errors = [CashbackExplorerErrors]()
        if let errorDetails = dictOfErrors[Keys.errors] as? [Any] {
            for error in errorDetails {
                guard let errorDetail = error as? [String: Any] else { continue }
                
                if let _ = errorDetail[Keys.name] {
                    errors.append(.invalidName)
                } else if let _ = errorDetail[Keys.cashback] {
                    errors.append(.invalidCashback)
                } else if let _ = errorDetail[Keys.city] {
                    errors.append(.invalidCity)
                } else if let _ = errorDetail[Keys.lat] {
                    errors.append(.invalidLat)
                } else if let _ = errorDetail[Keys.long] {
                    errors.append(.invalidLong)
                }
            }
        } else {
            errors.append(.unknown)
        }
        return errors
    }
}
