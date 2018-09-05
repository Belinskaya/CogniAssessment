//
//  VenuesListViewController.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit
import MapKit

class VenuesListViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var fakeNewYourLocation = CLLocation(latitude: 40.9499, longitude: -73.6696)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        mapView.delegate = self
        SessionManager.shared.locationManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapView.showsUserLocation = true
        SessionManager.shared.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            SessionManager.shared.locationManager.startUpdatingLocation()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.addNewVenue, let destinationVC  = segue.destination as? NewVenueViewController {
            destinationVC.delegate = self
        }
    }
    
    private func centerMapOn(location: CLLocation) {
        let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func startSearch(for city: String) {
        SessionManager.shared.getListOfVenues(for: city) { (result) in
            switch result {
            case .sussess:
                self.mapView.addAnnotations(SessionManager.shared.venues)
            case .failure(error: _):
                self.showGenericError()
            }
        }
    }
}

extension VenuesListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil}
        
        if let venueAnnotation = annotation as? Venue {
            let pin = ExplorerPinAnnotationView(with: venueAnnotation)
            return pin
        }
        
        return nil
    }
}

extension VenuesListViewController: NewVenueViewControllerDelegate {
    func newVenueWasAdded(_ venue: Venue) {
        navigationController?.popViewController(animated: true)
        mapView.addAnnotation(venue)
    }
}

extension VenuesListViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showGenericError(title: Constants.ErrorMessages.cantLocateTitle, message: Constants.ErrorMessages.defaultCityMessage)
        centerMapOn(location: fakeNewYourLocation)
        startSearch(for: Constants.defaultCity)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.first else { return }
        
        centerMapOn(location: userLocation)
        
        SessionManager.shared.locationManager.stopUpdatingLocation()
    }
}

extension VenuesListViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let cityname = searchBar.text else { return }
        
        startSearch(for: cityname)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
