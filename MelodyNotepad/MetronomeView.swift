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
    
    let unlitColor : UIColor = UIColor.whiteColor()
    let litColor : UIColor = UIColor.greenColor()
    
    let resetTime : NSTimeInterval = 0.1
    
    var lit : Bool = false
    var running : Bool = false
    
    var pulseTimer : NSTimer? = nil
    var relaxTimer : NSTimer? = nil
    
    var pulseInterval : NSTimeInterval = 0.5 // 120 BPM -> 0.5 seconds per beat
    
    var tempo : BPM {
        get {
            return 60 / pulseInterval
        }
        set(t) {
            pulseInterval = 60 / t
        }
    }

    override func drawRect(rect: CGRect) {
        (lit ? litColor : unlitColor).set()
        UIRectFill(rect)
    }
    
    @objc func pulse() {
        lit = true
        setNeedsDisplay()
        relaxTimer?.invalidate()
        relaxTimer = NSTimer.scheduledTimerWithTimeInterval(
            resetTime,
            target: self,
            selector: #selector(MetronomeView.relax),
            userInfo: nil,
            repeats: false)
    }
    
    @objc private func relax() {
        lit = false
        setNeedsDisplay()
    }
    
    func switchOn() {
        pulseTimer?.invalidate()
        pulse()
        pulseTimer = NSTimer.scheduledTimerWithTimeInterval(
            pulseInterval,
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
