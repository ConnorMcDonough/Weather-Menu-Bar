//
//  AppDelegate.swift
//  Weather Menu Bar
//
//  Created by Connor McDonough on 5/27/21.
//

import Cocoa
import SwiftyJSON


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var feed: JSON?
    var displayMode = 0
    var updateDisplayTimer: Timer?
    var fetchFeedTimer: Timer?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App has opened!")
        let defaultSettings = ["latitude": "51.507222", "longitude": "-0.1275", "apiKey": "-", "statusBarOption": "-1", "units": "0"]
        UserDefaults.standard.register(defaults: defaultSettings)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(loadSettings), name: Notification.Name("SettingsChanged"), object: nil)
        
        guard let statusButton = statusItem.button else { return }
        
        statusButton.title = "Featching..."
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showSettings)
        
        loadSettings()
    }
    
    func addConfigurationMenuItem() {
        let separator = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        statusItem.menu?.addItem(separator)
    }
    
    @objc func showSettings(_ sender: NSMenuItem) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ViewController") as? ViewController else {
            fatalError("Unable to find ViewController in the storyboard.")
        }
        
        guard let button = statusItem.button else {
            fatalError("Couldn't find status item button.")
        }
        
        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        
        updateDisplayTimer?.invalidate()
    }
    
    @objc func fetchFeed() {
        let defaults = UserDefaults.standard
        
        guard let apiKey = defaults.string(forKey: "apiKey") else { return }
        guard !apiKey.isEmpty else {
            statusItem.button?.title = "No API key"
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [unowned self] in
            let latitude = defaults.double(forKey: "latitude")
            let longitude = defaults.double(forKey: "longitude")
            
            var altDataSource = "http://api.openweathermap.org/data/2.5/onecall?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)"
            
            
            if defaults.integer(forKey: "units") == 0 {
                altDataSource += "&units=metric"
            } else {
                altDataSource += "&units=imperial"
            }
            
            guard let url = URL(string: altDataSource) else { return }
            guard let data = try? String(contentsOf: url) else {
                DispatchQueue.main.async { [unowned self] in
                    self.statusItem.button?.title = "Bad API call"
                }
                return
            }
            
            let newFeed = JSON(parseJSON: data)

            DispatchQueue.main.async {
                self.feed = newFeed
                self.updateDisplay()
            }

        }
    }
    
    @objc func loadSettings() {
        fetchFeedTimer = Timer.scheduledTimer(timeInterval: 60*5, target: self, selector: #selector(fetchFeed), userInfo: nil, repeats: true)
        fetchFeedTimer?.tolerance = 60
        
        fetchFeed()
        
        displayMode = UserDefaults.standard.integer(forKey: "statusBarOption")
        configureUpdateDisplayTimer()
    }
    
    func updateDisplay() {
        guard let feed = feed else { return }
        
        var text = "Error"
        
        switch displayMode {
        case 0:
            //Summary text
            if let summary = feed["current"]["weather"][0]["main"].string {
                text = "\(summary)"
            }
        case 1:
            //Show current temerature
            if let temperature = feed["current"]["temp"].int {
                text = "\(temperature)"
                if UserDefaults.standard.integer(forKey: "units") == 0 {
                    text += " ℃"
                } else {
                    text += " ℉"
                }
            }
        case 2:
            //Show chance of rain
            if let rain = feed["hourly"][0]["pop"].double {
                text = String(format: "%.0f", (rain*100))
                text += "% Chance"
            }
        case 3:
            //Show cloud cover
        if let cloud = feed["current"]["clouds"].double {
            text = "Cloud: \(cloud)%"
        }
        default:
            //Shouldn't come here
            print("You shouldn't be here")
            break
        }
        
        statusItem.button?.title = text
    
    }
    
    @objc func changeDisplayMode() {
        displayMode += 1

        if displayMode > 3 {
            displayMode = 0
        }

        updateDisplay()
    }
    
    func configureUpdateDisplayTimer() {
        guard let statusBarMode = UserDefaults.standard.string(forKey: "statusBarOption") else { return }
        
        if statusBarMode == "-1" {
            displayMode = 0
            updateDisplayTimer = Timer.scheduledTimer(timeInterval: 8, target: self, selector: #selector(changeDisplayMode), userInfo: nil, repeats: true)
        } else {
            updateDisplayTimer?.invalidate()
        }
    }

}
