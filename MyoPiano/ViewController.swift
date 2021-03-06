//
//  ViewController.swift
//  MyPianoiOS
//
//  Created by Pranay Neelagiri on 4/6/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//

import UIKit
import AVFoundation

extension String {
    var lines: [String] {
        var result: [String] = []
        enumerateLines { line, _ in result.append(line) }
        return result
    }
}

class ViewController : UIViewController, UIGestureRecognizerDelegate {
    var currentPose: TLMPose!
    //All outlets to keys and UI features
    @IBOutlet weak var libToolbar: UIToolbar!
    @IBOutlet weak var connectToolbar: UIToolbar!
    @IBOutlet weak var pianoView: UIView!
    @IBOutlet weak var connectionItem: UIBarButtonItem!
    @IBOutlet weak var libraryButton: UIBarButtonItem!
    @IBOutlet weak var recordingLabel: UIBarButtonItem!
    
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
    
    var isRecording:Bool = false
    var isConnected:Bool = false
    var canMove = true
    
    //2D arrays for holding EMG data, and their corresponding "fill" flags
    var arr1: [Float] = [], arr2: [Float] = []
    var means: [Float] = []
    var stds: [Float] = []
    var ct1 = 0, ct2 = 0
    var arr2Fill: Bool = false
    
    //Arrays and sets to keep track of the key(s) being pressed,
    //and the audio that goes with them
    var keys: [UIView]!
    // activeKeys: [UIView]! = []
    var map: [Int:String]!
    var pressedKey:UIView!
    var sounds: [String:AVAudioPlayer]!
    var track : [String]!
    
    //Used to keep track of horizontal motion through acceleration data
    var activeStart:Int!, pressed:Int! = -1
    var lastPosition: Double = 5.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifier = NotificationCenter.default
        
        // Data notifications are received through NSNotificationCenter.
        // Posted whenever a TLMMyo connects
        notifier.addObserver(self, selector: #selector(ViewController.didConnectDevice(_:)), name: NSNotification.Name.TLMHubDidConnectDevice, object: nil)
        
        // Posted whenever a TLMMyo disconnects.
        notifier.addObserver(self, selector: #selector(ViewController.didDisconnectDevice(_:)), name: NSNotification.Name.TLMHubDidDisconnectDevice, object: nil)
        
        //Create an observer for recieving EMG data
        notifier.addObserver(self, selector: #selector(ViewController.didReceiveEMGChange(_:)), name: NSNotification.Name.TLMMyoDidReceiveEmgEvent, object: nil)
        
        notifier.addObserver(self, selector: #selector(ViewController.didRecieveGyroscopeData(_:)),
            name: NSNotification.Name.TLMMyoDidReceiveGyroscopeEvent, object: nil)
        
        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateGyro), userInfo: nil, repeats: true)
        
        timer.fire()
        
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
        
        
        //Read from mean.txt and std.txt to create the normalization arrays
        let meanPath = Bundle.main.path(forResource: "pop_mean-2", ofType: "txt")
        let meanURL = URL(fileURLWithPath: meanPath!)
        
        let stdPath = Bundle.main.path(forResource: "pop_std-2", ofType: "txt")
        let stdURL = URL(fileURLWithPath: stdPath!)
        
        do {
            let meanText = try String(contentsOf: meanURL, encoding: String.Encoding.utf8)
            let stdText = try String(contentsOf: stdURL, encoding: String.Encoding.utf8)
            
            let meanStrings = meanText.lines
            for string in meanStrings {
                means.append(Float(string)!)
            }
            
            let stdStrings = stdText.lines
            for string in stdStrings {
                stds.append(Float(string)!)
            }
        } catch let error as Error {
            print(error.localizedDescription)
        }
        
        
        activeStart = 5
        updateKeys()
        //updatePressedKey(7)
        
        Model.loadGraph()
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
    }
    
    // MARK: NSNotificationCenter Methods
    @objc func didConnectDevice(_ notification: Notification) {
        // Access the connected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Connected to %@.", myo.name);
        
        connectionItem.title = "Connected"
        isConnected = true
        
        myo.setStreamEmg(TLMStreamEmgType.enabled)
    }
    
    @objc func didDisconnectDevice(_ notification: Notification) {
        // Access the disconnected device.
        let userinfo = notification.userInfo
        let myo:TLMMyo = (userinfo![kTLMKeyMyo] as? TLMMyo)!
        print("Disconnected from %@.", myo.name);
        
        isConnected = false
        
        connectionItem.title = "Disconnected"
    }
    
    @objc func predictAndPlay(_ inputArray: [Float]) {
        //Send data to the TensorFlow model to be processed
        var arrayCopy = inputArray
        for i in 0..<arrayCopy.count {
            arrayCopy[i] = (arrayCopy[i] - means[i]) / stds[i]
        }
        
        let resultIndex = Model.predict(UnsafeMutablePointer<Float>(&arrayCopy)) - 1
        if(resultIndex >= 0) {
            let keyIndex: Int = activeStart + Int(resultIndex)
            
            sounds[map[keyIndex]!]?.play()
            if(isRecording) {
                print(keyIndex)
                track.append(map[keyIndex]!)
            }
            updatePressedKey(keyIndex)
        } else {
            //Update the key, but we do not want a sound to be played
            updatePressedKey(-1)
            if(isRecording) {
                track.append("rest")
            }
        }
    }
    
    @objc func predictAndPlayThresh(_ inputArray: [Float]) {
        //Send data to the TensorFlow model to be processed
        var arrayCopy = inputArray
//        for i in 0..<arrayCopy.count {
////            arrayCopy[i] = (arrayCopy[i] - means[i]) / stds[i]
//        }
        
        var chosenKeyIndex: Int = 0
        var highHighResults: [Bool] = predictCrude(arrayCopy, 20, 45)
        var highResults: [Bool] = predictCrude(arrayCopy, 20, 40)
        var results: [Bool] = predictCrude(arrayCopy, 20, 30)
        var moderateResults: [Bool] = predictCrude(arrayCopy, 15, 20)
        
        var foundKey: Bool = false
        if(results[0]) {
            //Index finger
            if(highHighResults[3]) {
                chosenKeyIndex = 1
                foundKey = true
            } else if (moderateResults[7]) {
            //Middle
                chosenKeyIndex = 2
                foundKey = true
            }
            
        }
        if(!foundKey) {
            //Pinkie
            if(results[1]) {
                chosenKeyIndex = 4
            }
            //Thumb
            else if(highResults[2]) {
                chosenKeyIndex = 0
            }
            //None
            else {
                chosenKeyIndex = -1
            }
        }
        
        print(chosenKeyIndex)
        if(chosenKeyIndex >= 0) {
            let keyIndex: Int = activeStart + Int(chosenKeyIndex)
            
            sounds[map[keyIndex]!]?.play()
            if(isRecording) {
                print(keyIndex)
                track.append(map[keyIndex]!)
            }
            updatePressedKey(keyIndex)
        } else {
            //Update the key, but we do not want a sound to be played
            updatePressedKey(-1)
            if(isRecording) {
                track.append("rest")
            }
        }
    }
    
    @objc func didReceiveEMGChange(_ notification:Notification) {
        var userInfo = notification.userInfo
        let data = userInfo![kTLMKeyEMGEvent] as! TLMEmgEvent
        
        arr1 += (data.rawData as! [Float])
        ct1+=1
        
        if(!arr2Fill) {
            if(ct1 < 50) { return }
            else { arr2Fill = true }
        }
        
        arr2 += (data.rawData as! [Float])
        ct2+=1
        
        if(ct1 == 100) {
            //Send data to the TensorFlow model to be processed
            predictAndPlayThresh(arr1)
            //Reset array
            arr1 = []
            ct1 = 0
        } else if(ct2 == 100) {
            //Send data to the TensorFlow model to be processed
            predictAndPlayThresh(arr2)
            //Reset array
            arr2 = []
            ct2 = 0
        }
    }
    
    //Gives crude predictions for which electrodes are activated
    @objc func predictCrude(_ emgData: [Float], _ thresh: Float, _ numThreshRequired: Int) -> [Bool] {
        var retValues: [Bool] = []
        for electrode in 0..<8 {
            var numPastThresh: Int = 0
            for point in stride(from: electrode, to: 800, by: 8) {
                let data: Float = emgData[point]
                if(data > thresh || data < -1*thresh) {
                    numPastThresh += 1
                }
            }
            
//            print(numPastThresh)
            if(numPastThresh > numThreshRequired) {
                retValues.append(true)
            } else {
                retValues.append(false)
            }
        }
        
        return retValues
    }
    
    //When acceleration data is recieved, update timestamp, velocity, and position
    @objc func didRecieveGyroscopeData(_ notification: Notification) {
        
        if(canMove) {
            //Handle acceleration data
            let userInfo = notification.userInfo
            let data = userInfo![kTLMKeyGyroscopeEvent] as! TLMGyroscopeEvent

            let yGyro = data.vector.y
//            print(yGyro)
            
            if(abs(data.vector.x) > 30 || abs(data.vector.z) > 30) {
                return
            }
            
            let possibleStartActive = Float(lastPosition) + (yGyro+5) / 10
            activeStart = Int(possibleStartActive)

            activeStart = activeStart > 9 ? 9 : activeStart
            activeStart = activeStart < 0 ? 0 : activeStart
            lastPosition = Double(activeStart)
            updateKeys()
            canMove = false
        }
    }
    
    @objc func updateGyro() {
        canMove = true
    }
    
    @IBAction func toggleRecord() {
        if(isRecording) {
            stopRecording()
            if(isConnected) {
                createSound(soundFiles: track, outputFile: "test")
                track = []
            }
            isRecording = false
        } else {
            startRecording()
            isRecording = true
        }
    }
    
    func changeActiveKey(activeStart: Int) {
        self.activeStart = activeStart
    }
    
    //Update the color of the key actually being pressed (the one predicted
    //by the model)
    func updatePressedKey(_ activeIndex: Int) {
        for i in activeStart...(activeStart+4) {
            let key: UIView = keys[i]
            if(i == activeIndex) {
                key.backgroundColor = UIColor(red: 167.0/255, green: 187.0/255, blue: 236.0/255, alpha: 1.0)
            } else {
                key.backgroundColor = UIColor(red: 199.0/255, green: 211.0/255, blue: 242.0/255, alpha: 1.0)
            }
        }
    }
    
    //Update the color so that all the "active keys" (i.e. the ones that
    //the player can play) are activated and everything else is deactivated
    func updateKeys() {
        for i in 0...13 {
            let key: UIView = keys[i]
            if(i < activeStart || i > activeStart + 4) {
                key.backgroundColor = UIColor(red: 231.0/255, green: 236.0/255, blue: 249.0/255, alpha: 1.0)
            } else {
                key.backgroundColor = UIColor(red: 199.0/255, green: 211.0/255, blue: 242.0/255, alpha: 1.0)
            }
        }
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
                NSLog("All done creating audio file!!!");
            }
        }
    }
    
    func startRecording() {
        recordingLabel.image = UIImage(named: "stop")
        isRecording = true
    }
    
    func stopRecording() {
        recordingLabel.image = UIImage(named: "recording")
        isRecording = false
    }
}
