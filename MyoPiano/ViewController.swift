//
//  ViewController.swift
//  MyPianoiOS
//
//  Created by Pranay Neelagiri on 4/6/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController : UIViewController, UIGestureRecognizerDelegate {
    var currentPose: TLMPose!
    @IBOutlet weak var libToolbar: UIToolbar!
    @IBOutlet weak var connectToolbar: UIToolbar!
    @IBOutlet weak var pianoView: UIView!
    @IBOutlet weak var connectionItem: UIBarButtonItem!
    @IBOutlet weak var libraryButton: UIBarButtonItem!
    
    var arr1 = Array(repeating: Array(repeating: 0, count: 8), count: 100), arr2 = Array(repeating: Array(repeating: 0, count: 8), count: 100)
    var ct1 = 0, ct2 = 0
    var arr1Fill:Bool = true
    var arr2Fill: Bool = false
    
    @IBOutlet weak var key1: UIView!
    @IBOutlet weak var key2: UIView!
    @IBOutlet weak var key3: UIView!
    @IBOutlet weak var key4: UIView!
    @IBOutlet weak var key5: UIView!
    @IBOutlet weak var key6: UIView!
    @IBOutlet weak var key7: UIView!
    @IBOutlet weak var key8: UIView!
    @IBOutlet weak var key9: UIView!
    @IBOutlet weak var key10: UIView!
    @IBOutlet weak var key11: UIView!
    @IBOutlet weak var key12: UIView!
    @IBOutlet weak var key13: UIView!
    @IBOutlet weak var key14: UIView!
    
    var keys: [UIView]!, activeKeys: [UIView]!
    var pressedKey:UIView!
    var activeStart:Int!, activeEnd:Int!
    
    
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
        
        connectToolbar.isTranslucent = true
        libToolbar.isTranslucent = true
        
        keys = [key1: "C3",
                key2: "D3",
                key3: "E3",
                key4: "F3",
                key5: "G3",
                key6: "A3",
                key7: "B3",
                key8: "C4",
                key9: "D4",
                key10: "E4",
                key11: "F4",
                key12: "G4",
                key13: "A4",
                key14: "B4"]
        
        activeStart = 5; activeEnd = 9;
        
        for i in activeStart...activeEnd {
            activeKeys.append(keys[i])
        }
        
        for key in keys {
            key.layer.borderColor = UIColor.black.cgColor
            key.layer.borderWidth = 0.7
            
            let path = Bundle.main.path(forResource: note, ofType: "mp3")
            let url = URL(fileURLWithPath: path!)
            
            do {
                sounds[note] = try AVAudioPlayer(contentsOf: url)
            } catch let error as NSError {
                print(error.description)
            }
        }
        
        
        
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
        UIView.animate(withDuration: 2, animations: { () -> Void in
            self.connectToolbar.isHidden = !self.connectToolbar.isHidden
            self.libToolbar.isHidden = !self.libToolbar.isHidden
        })
        
        let player: AVAudioPlayer = sounds["C4"]!
        player.play()
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
