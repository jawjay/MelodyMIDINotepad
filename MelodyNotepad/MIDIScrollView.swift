//
//  MIDIScrollView.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 8/2/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import UIKit
class MIDIScrollView: UIScrollView {
    let midiView : MIDIView
    let playheadIndicator : PlayheadIndicator
    var audioProcessor : AudioProcessor? = nil
    
    override init(frame: CGRect) {
        
        self.midiView = MIDIView(frame: CGRect(x: frame.width / 2, y: 0.0, width: 800, height: 1280))
        self.midiView.backgroundColor = UIColor.whiteColor()
        
        self.playheadIndicator = PlayheadIndicator(frame: self.midiView.frame)
        
        super.init(frame: frame)
        
        self.canCancelContentTouches = false
        self.addSubview(midiView)
        
        self.addSubview(playheadIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.midiView = MIDIView(frame: CGRect(x: 0.0, y: 0.0, width: 800, height: 1280))
        self.midiView.backgroundColor = UIColor.whiteColor()
        
        self.playheadIndicator = PlayheadIndicator(frame: CGRect(x: 0.0, y: 0.0, width: 800, height: 1280))
        
        super.init(coder: aDecoder)
        self.canCancelContentTouches = false
        
        self.midiView.frame.offsetInPlace(dx: frame.midX, dy: 0)
        self.addSubview(midiView)
        self.addSubview(playheadIndicator)
        
        refresh()

        
    }
    
    func refresh() {
        midiView.refresh()
        midiView.sizeToFit()
        playheadIndicator.frame = midiView.frame
        self.contentSize = midiView.frame.size
        self.contentSize.width += self.frame.width
    }
    
    func openMelody(melody : Melody) {
        midiView.openMelody(melody)
        midiView.sizeToFit()
        playheadIndicator.frame = midiView.frame
        
        self.contentSize = midiView.frame.size
        self.contentSize.width += self.frame.width
        
        self.setContentOffset(CGPoint(x: 0, y: midiView.noteHeight*30), animated: false)
    }
    
    func moveToBeat(beats : Double) {
        let x = midiView.xFromBeats(beats)
        playheadIndicator.x = x
        playheadIndicator.setNeedsDisplay()
        
        self.setContentOffset(
            CGPoint(
                x: x,
                y: self.contentOffset.y),
            animated: false)
        
    }
    
    func setOffset(x : CGFloat) {
        self.midiView.frame = CGRect(origin: CGPoint(x: x, y: 0), size: self.midiView.frame.size)
        playheadIndicator.frame = self.midiView.frame
    }

}

class PlayheadIndicator : UIView {
    
    var x : CGFloat = 0
    var color : UIColor = UIColor.yellowColor()
    
    override init(frame : CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }
    
    override func drawRect(rect: CGRect) {
        let indicator = UIBezierPath()
        let x : CGFloat
        
        if self.x < self.bounds.minX {
            x = self.bounds.minX
        } else if self.x > self.bounds.maxX {
            x = self.bounds.maxX
        } else {
            x = self.x
        }
        
        indicator.moveToPoint(CGPoint(x: x, y: rect.minY))
        indicator.addLineToPoint(CGPoint(x: x, y: rect.maxY))
        
        color.setStroke()
        indicator.stroke()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("PlayheadIndicator.init(coder:) has not been implemented")
    }
    
}