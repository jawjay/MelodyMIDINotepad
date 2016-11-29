//
//  Transcriber.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 7/30/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import UIKit
import AudioKit

class Transcriber {
    
    // Transcription Parameters
    var thresholdAmp = 0.2  //  max:
    var thresholdDur = 0.06 // max: 30
    var thresholdNote = 30      // max:
    var ceilingNote = 100
    
    var sampleRate : Double = 32
    
    var samples : [(freq : Double, amp : Double)] = []
    
    fileprivate var tracker : AKFrequencyTracker?
    
    var timer : Timer?
    var sampling : Bool = false
    
    // Prepare for a new recording
    func reset() {
        samples.removeAll()
        timer?.invalidate()
    }
    
    // Sample current amplitude and frequency of AKFrequencyTracker
    @objc fileprivate func sample() {
        let sample = (freq: tracker!.frequency, amp: tracker!.amplitude)
        //print(sample) //Uncomment For debugging
        samples.append(sample)
    }

    func startSampling(_ tracker : AKFrequencyTracker) {
        stopSampling()
        
        self.tracker = tracker
        
        timer = Timer.scheduledTimer(
            timeInterval: 1.0 / sampleRate,
            target: self,
            selector: #selector(Transcriber.sample),
            userInfo: nil,
            repeats: true)
        
        self.sampling = true
    }
    
    func stopSampling() {
        if sampling {
            timer?.invalidate()
            self.sampling = false
        }
    }
    
    func extractMelody(tempo: BPM, offset : AKDuration) -> Melody {
        var preliminary : [Note] = []
        
        var index = 0 // Samples since beginning of recording
        var streak = 0 // Consecutive samples of same pitch and sufficient amplitude
        
        var current = MIDINoteNumber(round(samples.first!.freq.frequencyToMIDINote())) // Note value of last threshold-exceeding sample
        
        let beatsPerSample = (tempo / 60.0) / sampleRate
        
        for sample in samples {
            
            if sample.amp >= thresholdAmp {
                // Sample amplitude above threshold, signaling either a new note or continuation of the current
                
                let note = MIDINoteNumber(round(sample.freq.frequencyToMIDINote())) // Note of current sample
                
                if note == current {
                    // Continuation of current note (or beginning new note with same pitch as last valid sample)
                    streak += 1
                } else {
                    // Beginning of new note with different pitch than last valid sample
                    
                    if streak > 0 {
                        preliminary.append(Note(
                            value: current,
                            onset: (index-streak) * beatsPerSample,
                            duration: streak * beatsPerSample))
                    }
                    
                    current = note
                    streak = 1 // C-C-C-Combo breakerrrrr!
                }
            } else {
                // Sample amplitude below threshold, signaling either the end of a note or continuation of a rest
                
                if streak > 0 {
                    preliminary.append(Note(
                        value: current,
                        onset: (index-streak) * beatsPerSample,
                        duration: streak * beatsPerSample))
                }
                streak = 0
            }
            
            index += 1
        }
        
        if streak > 0 {
            preliminary.append(Note(
                value: current,
                onset: (index-streak) * beatsPerSample,
                duration: streak * beatsPerSample))
        }
        
        // Remove invalid notes, return melody with that
        
        let scrubbed = scrubNotes(preliminary)
        // print ("scrubbed \(preliminary.count - scrubbed.count) notes")
        return Melody(notes: scrubbed, tempo: tempo)
    }
    
    
    // Private utility for scrubbing out notes that the singer did not likely sing
    fileprivate func scrubNotes(_ notes : [Note]) -> [Note] {
        return notes.filter({$0.duration >= thresholdDur && $0.value >= thresholdNote && $0.value <= ceilingNote})
    }
    
    
    
    
}
