//
//  MetronomeView.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 8/3/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import UIKit
import AudioKit

class MetronomeView: UIView {
    
    let unlitColor : UIColor = UIColor.white
    let litColor : UIColor = UIColor.green
    
    let resetTime : TimeInterval = 0.1
    
    var lit : Bool = false
    var running : Bool = false
    
    var pulseTimer : Timer? = nil
    var relaxTimer : Timer? = nil
    
    var pulseInterval : TimeInterval = 0.5 // 120 BPM -> 0.5 seconds per beat
    
    var tempo : BPM {
        get {
            return 60 / pulseInterval
        }
        set(t) {
            pulseInterval = 60 / t
        }
    }

    override func draw(_ rect: CGRect) {
        (lit ? litColor : unlitColor).set()
        UIRectFill(rect)
    }
    
    @objc func pulse() {
        lit = true
        setNeedsDisplay()
        relaxTimer?.invalidate()
        relaxTimer = Timer.scheduledTimer(
            timeInterval: resetTime,
            target: self,
            selector: #selector(MetronomeView.relax),
            userInfo: nil,
            repeats: false)
    }
    
    @objc fileprivate func relax() {
        lit = false
        setNeedsDisplay()
    }
    
    func switchOn() {
        pulseTimer?.invalidate()
        pulse()
        pulseTimer = Timer.scheduledTimer(
            timeInterval: pulseInterval,
            target: self,
            selector: #selector(MetronomeView.pulse),
            userInfo: nil,
            repeats: true)
        running = true
    }
    
    func switchOff() {
        pulseTimer?.invalidate()
        running = false
    }

    
    
    

}
