//
//  ViewController.swift
//  Weather Menu Bar
//
//  Created by Connor McDonough on 5/27/21.
//

import Cocoa
import MapKit

class ViewController: NSViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var apiKey: NSTextField!
    @IBOutlet weak var statusBarOption: NSPopUpButton!
    @IBOutlet weak var units: NSSegmentedControl!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let defaults = UserDefaults.standard
        let savedLatitude = defaults.double(forKey: "latitude")
        let savedLongitude = defaults.double(forKey: "longitude")
        let savedAPIKey = defaults.string(forKey: "apiKey") ?? ""
        let savedStatusBar = defaults.integer(forKey: "statusBarOption")
        let savedUnits = defaults.integer(forKey: "units")
        
        apiKey.stringValue = savedAPIKey
        units.selectedSegment = savedUnits
        
        for menuItem in statusBarOption.menu!.items {
            if menuItem.tag == savedStatusBar {
                statusBarOption.select(menuItem)
            }
        }
        
        let savedLocation = CLLocationCoordinate2D(latitude: savedLatitude, longitude: savedLongitude)
        addPin(at: savedLocation)
        mapView.centerCoordinate = savedLocation
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(recognizer)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        let defaults = UserDefaults.standard
        
        let annotation = mapView.annotations[0]
        defaults.set(annotation.coordinate.latitude, forKey: "latitude")
        defaults.set(annotation.coordinate.longitude, forKey: "longitude")
        defaults.set(apiKey.stringValue, forKey: "apiKey")
        defaults.set(units.selectedSegment, forKey: "units")
        
        var statusBarValue = -1
        
        for menuItem in statusBarOption.menu!.items {
            if menuItem.state == .on {
                statusBarValue = menuItem.tag
                break
            }
        }
        
        defaults.set(statusBarValue, forKey: "statusBarOption")
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("SettingsChanged"), object: nil)
    }
    
    
    func addPin(at coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Your location"
        mapView.addAnnotation(annotation)
    }
    
    @objc func mapTapped(recognizer: NSClickGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        
        let location = recognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        addPin(at: coordinate)
    }
    
    @IBAction func showPoweredBy(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://openweathermap.org/")!)
    }
    
    @IBAction func exitApplication(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    
}
