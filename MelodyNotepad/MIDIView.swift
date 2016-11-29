//
//  MIDIView.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 7/25/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import UIKit
import AudioKit

class MIDIView: UIView {
    
    var beatWidth : CGFloat = 80 //How wide one beat (column) should be
    var noteHeight : CGFloat = 16 //How tall one note (cell) should be
    
    let minimumDisplayWidth : CGFloat = 500
    
    let noteFill = UIColor.red
    let selectedFill = UIColor.orange

    let gridStroke = UIColor.gray //Color of gridlines
    let rowFill = UIColor.lightGray //Color of pitch rows of black keys

    // Currently opened melody
    var melody : Melody? = nil
    
    // See NoteBox class below
    fileprivate var boxes : [NoteBox] = []
    
    // Editing variables
    fileprivate var selectedBox : NoteBox? = nil
    fileprivate var boxOp : NoteOperation = .translate
    fileprivate var dx : CGFloat = 0
    fileprivate var dy : CGFloat = 0
    
    let boxHandleRatio : CGFloat = 0.15 // What fraction of note box is a "stretch note" handle....
    let boxHandleMax : CGFloat = 10  // ....unless its wider than this (impose restraint)
    
    static let blackKeysInLowestOctave = [1, 3, 6, 8, 10] // C#/Db, D#/Eb, F#/Gb, G#/Ab, and A#/Bb
    
    var shortestNote = 0.0625 // 1/16 of a beat (1/64 note)
    
    var playhead : AKDuration? = nil
    var playheadColor = UIColor.yellow
    
    
    //Internal class used to maintain relationship between Note objects and their on-screen represenation
    fileprivate class NoteBox {
        var note : Note
        var rect : CGRect
        
        init(note: Note, rect: CGRect) {
            self.note = note
            self.rect = rect
        }
        
    }
    
    //Enumeration for editing operations
    fileprivate enum NoteOperation {
        case translate, stretchLeft, stretchRight
    }
    
    override func draw(_ rect: CGRect) {
        //Draw gridlines
        
        let grid = UIBezierPath()
        
        //Beat dividers
        stride(from: ceil(rect.minX / beatWidth), to: rect.maxX, by: beatWidth).forEach(
            { x in
                grid.move(to: CGPoint(x: x, y: rect.minY))
                grid.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
        )
        
        //Grey bars for black keys, gridlines (between E and F) and (between B and C)
        stride(from: ceil(rect.minY / noteHeight), to: rect.maxY, by: noteHeight).forEach(
            { y in
                let key = (127 - Int(y / noteHeight)) % 12
                if MIDIView.blackKeysInLowestOctave.contains(key) {
                    //Black keys
                    rowFill.set()
                    UIRectFill(CGRect(x: rect.minX, y: y, width: rect.width, height: noteHeight))
                } else if key == 4 || key == 11 {
                    //E and B
                    grid.move(to: CGPoint(x: rect.minX, y: y))
                    grid.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
            }
        )
        
        gridStroke.setStroke()
        grid.stroke()
        
        //Draw notes as boxes
        
        if selectedBox != nil {
            for box in boxes {
                (selectedBox! === box ? selectedFill : noteFill).set()
                UIRectFill(box.rect)
            }
        } else {
            noteFill.set()
            boxes.forEach({UIRectFill($0.rect)})
        }
        
        //Draw playhead
        if let playhead = self.playhead {
            let x = xFromBeats(playhead.beats)
            if rect.contains(CGPoint(x: x, y: rect.midY)) {
                let indicator = UIBezierPath()
            
                indicator.move(to: CGPoint(x: x, y: rect.minY))
                indicator.addLine(to: CGPoint(x: x, y: rect.maxY))
                
                playheadColor.setStroke()
                indicator.stroke()
            }
        }
        
        
    }
    
    func deleteSelected() {
        guard let melody = self.melody else { return }
        guard let selectedBox = self.selectedBox else {return}
    
        
        // Worth having two separate loops in case boxes and melody get out of sync
        for i in 0..<melody.notes.count {
            if melody.notes[i] === selectedBox.note {
                melody.notes.remove(at: i)
                break
            }
        }
        
        for j in 0..<boxes.count {
            if boxes[j] === selectedBox {
                boxes.remove(at: j)
                break
            }
        }
        
        self.selectedBox = nil
        
        self.setNeedsDisplay()
    }
    
    //Display a melody
    func openMelody(_ melody : Melody) {
        self.melody = melody
        sizeToFit()
        refresh()
    }

    func refresh() {
        generateNoteBoxes()
        self.setNeedsDisplay()
    }
    
    func generateNoteBoxes() {
        if melody != nil {
            self.boxes = self.melody!.notes.map(boxFromNote)
        } else {
            self.boxes.removeAll()
        }
    }

    
    // Utilities for converting between notes and rectangles
    
    fileprivate func boxFromNote(_ note : Note) -> NoteBox {
        return NoteBox(
            note: note,
            rect: rectFromNote(note)
        )
        
    }
    
    fileprivate func rectFromNote(_ note : Note) -> CGRect {
        return CGRect(
            x: xFromBeats(note.onset),
            y: yFromPitch(note.value),
            width: xFromBeats(note.duration),
            height: noteHeight
        )
    }
    
    func beatsFromX(_ x : CGFloat) -> Double {
        return Double(x / beatWidth)
    }
    
    func xFromBeats(_ beats : Double) -> CGFloat {
        return beatWidth * CGFloat(beats)
    }
    
    func pitchFromY(_ y : CGFloat) -> MIDINoteNumber {
        return (127 - Int(y / noteHeight))
    }
    
    func yFromPitch(_ pitch : MIDINoteNumber) -> CGFloat {
        return noteHeight * CGFloat(127 - pitch)
    }
    
    override func sizeToFit() {
        if melody != nil {
            self.frame = CGRect(
                x: self.frame.minX,
                y: self.frame.minY,
                width: max(xFromBeats(melody!.duration().beats), minimumDisplayWidth),
                height: noteHeight * 128)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for box in boxes {
            if box.rect.contains(point) {
                return self // 'Note box was struck, so I'll handle this touch'
            }
        }
        
        return nil // 'No note boxes hit, so my superview should handle it'
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        
        /* Could probably do this part in HitTest so checking each box doesn't have to happen twice,
         but I'm not sure if HitTest always getting called immediately before the corresponding touchesBegan is a guarantee */
        
        for box in boxes {
            if box.rect.contains(point) {
                selectedBox = box
                dx = 0
                dy = 0
                
                let handleSize = min(box.rect.width * boxHandleRatio, boxHandleMax)
                
                if box.rect.divided(atDistance: handleSize, from: CGRectEdge.minXEdge).slice.contains(point) {
                    boxOp = .stretchLeft
                } else if box.rect.divided(atDistance: handleSize, from: CGRectEdge.maxXEdge).slice.contains(point) {
                    boxOp = .stretchRight
                } else {
                    boxOp = .translate
                }
                self.setNeedsDisplay()
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let box = selectedBox else {
            return
        }
        
        let touch = touches.first!
        let current = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        
        // Add touch's movement to running totals, passed INOUT to note manipulating functions
        // Which may or may not clear them depending on the validity of the note manipulation
        
        dx += current.x - previous.x
        dy += current.y - previous.y
        
        switch (boxOp) {
        case .translate:
            translate(box, dx: &dx, dy: &dy)
        case .stretchLeft:
            stretchLeft(box, dx: &dx)
        case .stretchRight:
            stretchRight(box, dx: &dx)
        }
    }
    
    fileprivate func translate(_ box : NoteBox, dx : inout CGFloat, dy : inout CGFloat) {
        let dBeats = beatsFromX(dx)
        
        //Are you attempting to move the note before 0 time?
        if dBeats < -box.note.onset {
            //Attempting to move note before 0 time, stop note at 0
            
            dx += box.rect.minX //Leave "unused" portion of dx †

            
            /*
             
             † To understand why this is important, try replacing it with a "dx = 0" and test the behavior when dragging note all the way left--past 0 time--and then, without lifting your finger, dragging back to the right:
             
               The note will be stopped at 0, but as soon as your finger moves to the right, the note will be pushed to the right, regardless of how far left of 0 your finger is. (Hard to explain, easier to demonstrate)
             */
            
            box.note.onset = 0.0
            box.rect = CGRect(x: 0.0, y: box.rect.minY, width: box.rect.width, height: box.rect.height)
        } else {
            // Otherwise, move note as usual
            box.note.onset += dBeats
            box.rect.offsetBy(dx: dx, dy: 0)
            dx = 0
        }
        
        // Is the running total of change in y greater in magnitude than the height of a note?
        if abs(dy) > noteHeight {
            
            //Calculate the change in MIDI pitch
            let change = dy > 0 ? -Int(abs(dy) / noteHeight) : Int(abs(dy) / noteHeight)
            
            //Change pitch, move box
            box.note.value += change
            box.rect.offsetBy(dx: 0.0, dy: -noteHeight * CGFloat(change))
            
            //Leave "unused" risidual portion of y (ensures that note will remain beneath the finger)
            dy += CGFloat(change) * noteHeight
        }
        
        setNeedsDisplay()
    }
    
    fileprivate func stretchRight(_ box : NoteBox, dx: inout CGFloat ) {
        
        //Make change in note length
        box.note.duration += beatsFromX(dx)
        
        
        //Did that make the note really short and/or give it negative duration?
        
        if box.note.duration < shortestNote {
            // Yes, note should be stopped at shortest possible length
            
            // Only take what you use from running total (see Translate(_:_:) for an analogous explanation)
            dx = -xFromBeats(shortestNote - box.note.duration)
            
            box.note.duration = shortestNote
            
        } else {
            dx = 0
        }
        
        box.rect = rectFromNote(box.note)
        
        setNeedsDisplay()
    }
    
    fileprivate func stretchLeft(_ box : NoteBox, dx: inout CGFloat ) {
        //See stretchRight for explanation
        
        let dDur = beatsFromX(dx)
        box.note.duration -= dDur
        
        if box.note.duration < shortestNote {
            let dDurUnused = shortestNote - box.note.duration
            dx = xFromBeats(dDurUnused)
            box.note.onset += dDur - dDurUnused
            box.note.duration = shortestNote
        } else {
            box.note.onset += dDur
            dx = 0
        }
        
        box.rect = rectFromNote(box.note)
        
        setNeedsDisplay()
    }


}
