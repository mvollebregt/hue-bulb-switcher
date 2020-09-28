//
//  AppDelegate.swift
//  lampaan
//
//  Created by Michel Vollebregt on 2020-09-28.
//

import Cocoa
import SwiftUI

struct State: Encodable, Decodable {
    var on: Bool;
}

struct Lightbulb: Decodable {
    var state: State;
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "LampUit")
            button.action = #selector(switchLight(_:))
        }
        checkLightStatus() {(statusOn) in
            self.setIcon(statusOn)
        }
    }
    
    @objc func switchLight(_ sender: AnyObject?) {
        
        checkLightStatus{(statusOn) in
            do {
                
                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
                let newState = State(on: !statusOn);
                let putUrl = URL(string: "\(bulbUrl)/state")!
                var request = URLRequest(url: putUrl)
                request.httpMethod = "PUT"
                request.httpBody = try JSONEncoder().encode(newState)
                request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
                
                let putTask = session.dataTask(with: request) { (data, response, error) in
                    self.setIcon(newState.on)
                }
                putTask.resume()
                
            } catch {
                print("Could not switch light")
            }
        }
    }
    
    func checkLightStatus(completionHandler: @escaping (_ status: Bool) -> Void) {
        
        let url = URL(string: bulbUrl)!
        let decoder = JSONDecoder()
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: url) {(data, response, error) in
            do {
                guard let data = data else { return }
                let bulb = try decoder.decode(Lightbulb.self, from: data)
                completionHandler(bulb.state.on)
            } catch {
                print("Could not determine light status")
            }
        }
        task.resume()
    }
    
    func setIcon(_ lightOn: Bool) {
        if let button = self.statusBarItem.button {
            DispatchQueue.main.async {
                button.image = NSImage(named: lightOn ? "LampAan" : "LampUit")
            }
        }
    }
}

extension AppDelegate: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //Trust the certificate even if not valid
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        
        completionHandler(.useCredential, urlCredential)
    }
}
