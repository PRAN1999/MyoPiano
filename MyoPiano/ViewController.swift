//
//  ViewController.swift
//  MyPianoiOS
//
//  Created by Pranay Neelagiri on 4/6/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//

import UIKit


class ViewController : UIViewController, UIGestureRecognizerDelegate {
    var currentPose: TLMPose!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var pianoView: UIView!
    @IBOutlet weak var connectionItem: UIBarButtonItem!
    
    var arr1 = Array(repeating: Array(repeating: 0, count: 8), count: 100), arr2 = Array(repeating: Array(repeating: 0, count: 8), count: 100)
    var ct1 = 0, ct2 = 0
    var arr1Fill:Bool = true
    var arr2Fill: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifer = NotificationCenter.default
        
        // Data notifications are received through NSNotificationCenter.
        // Posted whenever a TLMMyo connects
        notifer.addObserver(self, selector: #selector(ViewController.didConnectDevice(_:)), name: NSNotification.Name.TLMHubDidConnectDevice, object: nil)
        
        // Posted whenever a TLMMyo disconnects.
        notifer.addObserver(self, selector: #selector(ViewController.didDisconnectDevice(_:)), name: NSNotification.Name.TLMHubDidDisconnectDevice, object: nil)
        
        notifer.addObserver(self, selector: #selector(ViewController.didReceiveEMGChange(_:)), name: NSNotification.Name.TLMMyoDidReceiveEmgEvent, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        tap.delegate = self
        pianoView.addGestureRecognizer(tap)
        
        toolbar.isTranslucent = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapSettings(_ sender: AnyObject) {
        // Settings view must be in a navigation controller when presented
        let controller = TLMSettingsViewController.settingsInNavigationController()
        present(controller!, animated: true, completion: nil)
    }
    
    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        toolbar.isHidden = !toolbar.isHidden
    }
    // MARK: NSNotificationCenter Methods
    
    @objc func didConnectDevice(_ notification: Notification) {
        // Access the connected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Connected to %@.", myo.name);
        
        connectionItem.title = "Connected"
        
        myo.setStreamEmg(TLMStreamEmgType.enabled)
    }
    
    @objc func didDisconnectDevice(_ notification: Notification) {
        // Access the disconnected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Disconnected from %@.", myo.name);
        
        connectionItem.title = "Disconnected"
    }
    
    @objc func didReceiveEMGChange(_ notification:Notification) {
        var userInfo = notification.userInfo
        let data = userInfo![kTLMKeyEMGEvent] as! TLMEmgEvent
        
        arr1[ct1] = data.rawData as! [Int]
        ct1+=1
        
        if(!arr2Fill) {
            if(ct1 < 50) { return }
            else { arr2Fill = true }
        }
        
        arr2[ct2] = data.rawData as! [Int]
        ct2+=1
        
        if(ct1 == 100) {
            print(arr1)
            ct1 = 0
        } else if(ct2 == 100) {
            print(arr2)
            ct2 = 0
        }
    }
}
