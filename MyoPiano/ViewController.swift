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
    //All outlets to keys and UI features
    @IBOutlet weak var libToolbar: UIToolbar!
    @IBOutlet weak var connectToolbar: UIToolbar!
    @IBOutlet weak var pianoView: UIView!
    @IBOutlet weak var connectionItem: UIBarButtonItem!
    @IBOutlet weak var libraryButton: UIBarButtonItem!
    
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
    
    //2D arrays for holding EMG data, and their corresponding "fill" flags
    var arr1 = Array(repeating: Array(repeating: 0, count: 8), count: 100), arr2 = Array(repeating: Array(repeating: 0, count: 8), count: 100)
    var ct1 = 0, ct2 = 0
    var arr2Fill: Bool = false
    
    //Arrays and sets to keep track of the key(s) being pressed,
    //and the audio that goes with them
    var keys: [UIView]!
    // activeKeys: [UIView]! = []
    var map: [Int:String]!
    var pressedKey:UIView!
    var sounds: [String:AVAudioPlayer]!
    
    //Used to keep track of horizontal motion through acceleration data
    var activeStart:Int!, pressed:Int! = -1
    let g: Double = 9.80665 //gravitational constant of acceleration
    var acceleration: Double = 0.0
    var lastPosition: Double = 0.0
    var lastVelocity: Double = 0.0
    var lastTimestamp: Date = Date.init(timeIntervalSinceNow: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        testModel()
        let notifier = NotificationCenter.default
        
        // Data notifications are received through NSNotificationCenter.
        // Posted whenever a TLMMyo connects
        notifier.addObserver(self, selector: #selector(ViewController.didConnectDevice(_:)), name: NSNotification.Name.TLMHubDidConnectDevice, object: nil)
        
        // Posted whenever a TLMMyo disconnects.
        notifier.addObserver(self, selector: #selector(ViewController.didDisconnectDevice(_:)), name: NSNotification.Name.TLMHubDidDisconnectDevice, object: nil)
        
        //Create an observer for recieving EMG data
        notifier.addObserver(self, selector: #selector(ViewController.didReceiveEMGChange(_:)), name: NSNotification.Name.TLMMyoDidReceiveEmgEvent, object: nil)
        
        notifier.addObserver(self, selector: #selector(ViewController.didRecieveAccelData(_:)),
            name: NSNotification.Name.TLMMyoDidReceiveAccelerometerEvent, object: nil)
        
        //Create an gesture recognizer to hide and show the top and bottom toolbars
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        tap.delegate = self
        pianoView.addGestureRecognizer(tap)
        
        connectToolbar.isTranslucent = true
        libToolbar.isTranslucent = true
        
        
        keys = [key1, key2, key3, key4, key5, key6, key7,
                key8, key9, key10, key11, key12, key13, key14]
        
        map = [0: "C3", 1: "D3", 2: "E3", 3: "F3", 4: "G3",
               5: "A3", 6: "B3", 7: "C4", 8: "D4", 9: "E4",
               10: "F4", 11: "G4", 12: "A4", 13: "B4"]
        
        sounds = [String:AVAudioPlayer]()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error.description)
        }
        
        var i:Int = 0
        for key in keys {
            key.layer.borderColor = UIColor.black.cgColor
            key.layer.borderWidth = 0.7
            
            let path = Bundle.main.path(forResource: map[i]!, ofType: "mp3")
            let url = URL(fileURLWithPath: path!)
            
            do {
                sounds[map[i]!] = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                sounds[map[i]!]?.prepareToPlay()
            } catch let error as NSError {
                print(error.description)
            }
            
            i += 1
        }
        
        
        //Indicates which keys the user can press, activeStart pointing to the
        //thumb and activeEnd pointing to pinkie
        activeStart = 5
        
        //Unnecesary since we only need to keep track of where the thumb is
//        for i in activeStart...activeEnd {
//            activeKeys.append(keys[i])
//        }
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
        
        //Test play sound
        let player: AVAudioPlayer = sounds["B3"]!
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
    
    @objc func didRecieveAccelData(_ notification: Notification) {
        //Handle acceleration data
        let userInfo = notification.userInfo
        let data = userInfo![kTLMKeyAccelerometerEvent] as! TLMAccelerometerEvent
        
        let currTimestamp: Date = data.timestamp
        let elapsedTime = currTimestamp.timeIntervalSince(lastTimestamp)
        acceleration = Double(data.vector.y) * g
        
        lastVelocity = getVelocity(accel: acceleration, timeElapsed: elapsedTime)
        lastTimestamp = currTimestamp
        
        changePosition(velocity: lastVelocity, accel: acceleration, timeElapsed: elapsedTime)
    }
    
    func changeActiveKey(activeStart: Int) {
        self.activeStart = activeStart
    }
    
    func changePosition(velocity:Double, accel:Double, timeElapsed:Double) {
        lastPosition += (lastVelocity * timeElapsed) + 0.5 * accel * (timeElapsed * timeElapsed)
    }
    
    func getVelocity(accel:Double, timeElapsed:Double) -> Double {
        return lastVelocity + (accel * timeElapsed)
    }
    
    //Generates an audio file by concatenating all the
    //audio filenames given in list provided
    func createSound(soundFiles: [String], outputFile: String) {
        var startTime: CMTime = kCMTimeZero
        let composition: AVMutableComposition = AVMutableComposition()
        let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        for fileName in soundFiles {
            let sound: String = Bundle.main.path(forResource: fileName, ofType: "mp3")!
            let url: URL = URL(fileURLWithPath: sound)
            let avAsset: AVURLAsset = AVURLAsset(url: url)
            let timeRange: CMTimeRange = CMTimeRangeMake(kCMTimeZero, avAsset.duration)
            let audioTrack: AVAssetTrack = avAsset.tracks(withMediaType: AVMediaType.audio)[0]
            
            try! compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: startTime)
            startTime = CMTimeAdd(startTime, timeRange.duration)
        }
        
        let exportPath: String = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path+"/"+outputFile+".m4a"
        
        let export: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
        
        export.outputURL = URL(fileURLWithPath: exportPath)
        export.outputFileType = AVFileType.m4a
        
        export.exportAsynchronously {
            if export.status == AVAssetExportSessionStatus.completed {
                NSLog("All done");
            }
        }
        
    }
}
