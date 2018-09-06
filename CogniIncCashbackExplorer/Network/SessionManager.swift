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
    
    func singIn(with user: User, completionHandler: @escaping LoginCompletionHadler) {
        var action = LoginActionType.signin
        if let tokenData = Locksmith.loadDataForUserAccount(userAccount: user.key),
            let savedToken = tokenData[Keys.token] as? String,
            let creationDate = tokenData[Keys.tokenCreationDate] as? Date {
            self.token = savedToken
            if Date().timeIntervalSince(creationDate) < Constants.thirtyDays {
                completionHandler(.sussess)
                return
            }
            action = .update
        }
        login(with: user, actionType: action, completionHandler: completionHandler)
    }
    
    private func login(with user: User, actionType: LoginActionType, completionHandler: @escaping LoginCompletionHadler) {
        let body: Parameters = [Keys.name: user.name, Keys.email: user.email]
        let headers: HTTPHeaders? = (actionType == .update && token != nil) ? [Keys.token: token!] : nil
        Alamofire.request(baseURL + actionType.rawValue, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 201...202)
            .responseString { response in
                switch response.result {
                case .failure(_):
                    guard let json = self.getJSON(from: response.data) else {
                        completionHandler(.failure(error: [.unknown]))
                        return
                    }
                    let error = self.parseUserError(in: json)
                    completionHandler(.failure(error: [error]))
                case .success(_):
                    if self.saveToken(from: response.response, withKey: user.key) {
                        completionHandler(.sussess)
                    } else {
                         completionHandler(.failure(error: [.unknown]))
                    }
                }
        }
    }
    
    func addNewVenue(_ venue: Venue, completionHandler: @escaping CashbackExplorerCompletionHadler) {
        guard let token = token else {
            completionHandler(.failure(error: [.unknown]))
            return
        }
        
        let body: Parameters = [Keys.name: venue.name, Keys.city: venue.city, Keys.lat: venue.lat, Keys.long: venue.long, Keys.cashback: venue.cashback]
        let headers: HTTPHeaders = [Keys.token: token]
        Alamofire.request(baseURL + "/venues", method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(_):
                    guard let json = self.getJSON(from: response.data) else {
                        completionHandler(.failure(error: [.unknown]))
                        return
                    }
                    let errors = self.parseVenueError(in: json)
                    completionHandler(.failure(error: errors))
                    return
                    
                case .success(let json):
                    if let responseDict = json as? [String: Any],
                        let venueDict = responseDict[Keys.venue] as? [String: Any],
                        let venue = Venue.parse(dict: venueDict) {
                            self.venues.append(venue)
                            completionHandler(.sussess(data: [venue]))
                            return
                    }
                    completionHandler(.failure(error: [.unknown]))
                }
        }
    }
    
    func getListOfVenues(for city: String = Constants.defaultCity, completionHandler: @escaping CashbackExplorerCompletionHadler) {
        guard let token = token else {
            completionHandler(.failure(error: [.unknown]))
            return
        }
        let headers: HTTPHeaders = [Keys.token: token]
        let parameters: Parameters = [Keys.city: city]
        Alamofire.request(baseURL + "/venues", method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(_):
                    completionHandler(.failure(error: [.unknown]))
                    return
                case .success(let json):
                    if let responseDict = json as? [String: Any],
                        let venueDict = responseDict[Keys.arrayOfVenues] as? [Any] {
                        let venues = venueDict.map({ (entry) -> [String: Any]? in
                            return entry as? [String: Any]
                            })
                            .compactMap { $0 }
                            .map({ venueDict -> Venue? in
                                return Venue.parse(dict: venueDict)
                            })
                            .compactMap { $0 }
        
                        self.venues = venues
                        completionHandler(.sussess(data: venues))
                        return
                    }
                    completionHandler(.failure(error: [.unknown]))
                }
        }
    }
    
    private func saveToken(from response: HTTPURLResponse?, withKey key: String) -> Bool {
        guard let response = response,
            let responseToken = response.allHeaderFields[Keys.token] as? String else { return false }
        
        self.token = responseToken
        
        let tokenData: [String: Any] = [Keys.token: responseToken, Keys.tokenCreationDate: Date()]
        //throw error here?
        try? Locksmith.saveData(data: tokenData, forUserAccount: key)
        
        return true
    }
    
    private func getJSON(from data: Data?) -> Any? {
        guard let data = data else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
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
