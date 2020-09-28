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
                    button.image = NSImage(named: "LampAan")
                    button.action = #selector(switchLight(_:))
        }
    }
    
    @objc func switchLight(_ sender: AnyObject?) {
        
        let url = URL(string: bulbUrl)!
        let decoder = JSONDecoder()
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: url) {(data, response, error) in
            do {
                guard let data = data else { return }
                var bulb = try decoder.decode(Lightbulb.self, from: data)
                bulb.state.on = !bulb.state.on
                
                let putUrl = URL(string: "\(bulbUrl)/state")!
                var request = URLRequest(url: putUrl)
                request.httpMethod = "PUT"
                request.httpBody = try JSONEncoder().encode(bulb.state)
                request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
                
                let putTask = session.dataTask(with: request) { (data, response, error) in
                    do {
                        if let button = self.statusBarItem.button {
                            DispatchQueue.main.async {
                                button.image = NSImage(named: bulb.state.on ? "LampAan" : "LampUit")
                            }
                        }
                    }
                }
                putTask.resume()
                
            } catch {
                print("Could not switch light")
            }
        }

        task.resume()
    }
}

extension AppDelegate: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       //Trust the certificate even if not valid
       let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)

       completionHandler(.useCredential, urlCredential)
    }
}
