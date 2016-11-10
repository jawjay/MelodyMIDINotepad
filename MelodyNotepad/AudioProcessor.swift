//
//  AudioProcessor.swift
//  MelodyNotepad
//
//  Created by Mark Jajeh on 7/24/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//
import UIKit
import AudioKit
import AVFoundation

class AudioProcessor {
    static let sharedInstance = AudioProcessor()
    
    let midi = AKMIDI()
    let sequencer = AKSequencer() // Plays back melodies
    let mic : AKMicrophone!
    var silence : AKBooster!
    let tracker : AKFrequencyTracker
    
    var sound : AKMIDINode // Recieves MIDI output from sequencer, generates sound
    
    let transcriber = Transcriber()
    
    var status : AudioStatus = .Idle
    
    enum AudioStatus {
        case Idle, Record, Playback
    }
    
    // Melody to record to/play back
    var melody : Melody?
    
    var offset : AKDuration = AKDuration(beats: 0) // Set to playhead at beginning of recording session
    
    // Timer responsible for stopping playback when end of melody is reached
    var autostop : NSTimer?
    
    //Callback functions
    var stopPlaybackCallback : (() -> ())? = nil
    
    // Workaround because AudioKit is bad at tempos
    // Use instead of sequencer.currentPosition and sequencer.setTime() (though sequencer.rewind() is still okay)
    var playhead : AKDuration {
        get {
            let pos = sequencer.currentPosition
            if melody != nil {
                return AKDuration.init(beats: pos.beats, tempo: melody!.tempo)
            } else {
                return pos
            }
        }
        set(dur) {
            sequencer.setTime(dur.musicTimeStamp)
        }
    }
    
    // Workaround: read and set instead of AKSequencer.length and AKSequencer.setLength
    var endtime : AKDuration = AKDuration(samples: 0)
    
    
    init() {
        sequencer.newTrack()
        sound = AKMIDINode(node: AKOscillatorBank())
        
        AKSettings.audioInputEnabled = true
        
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0.0)
    }
    
    // Clears sequencer's first track and copies melody into it, returns boolean indicating success
    private func loadMelodyIntoSequencer() -> Bool {
        guard let melody = self.melody else { return false }
        
        sequencer.tracks.first!.clear()
        
        melody.copyToTrack(sequencer.tracks.first!)
        sequencer.setTempo(melody.tempo)
        endtime = melody.duration()
        
        return true
    }
    
    
    // RECORDING //
    
    func startRecording() {
        switch status {
        case .Playback:
            stopPlayback()
        case .Record:
            return
        case .Idle:
            break
        }

        offset = AKDuration(beats: 0)
        // offset = self.playhead
        
        transcriber.startSampling(tracker)
        
        AudioKit.output = silence
        status = .Record
        AudioKit.start()

    }
    
    
    func stopRecording() {
        guard status == .Record else { return }
        
        // Stop recording process
        transcriber.stopSampling()
        AudioKit.stop()
        status = .Idle
        
        if melody != nil {
            melody!.join(transcriber.extractMelody(tempo: melody!.tempo, offset: offset))
        } else {
            melody = transcriber.extractMelody(tempo: melody!.tempo, offset: offset)
        }
        
        transcriber.reset()
    }
    
    // PLAYBACK //
    
    func startPlayback() {
        switch status {
        case .Playback:
            return
        case .Record:
            stopRecording()
        case .Idle:
            break
        }
        
        guard loadMelodyIntoSequencer() else { return }
        
        // If the user's already that close to the end, odds are they want to play from beginning
        if playhead >= endtime - AKDuration(seconds: 0.05) {
            sequencer.rewind()
        }
        
        // Start AudioKit and route sound generator to speakers
        AudioKit.output = sound
        AudioKit.start()
        
        // Connect sequencer to sound generator, play sequencer
        sequencer.setGlobalMIDIOutput(sound.midiIn)
        sequencer.play()
        
        // Schedule an automatic stop when the melody ends
        scheduleAutostop()
        
        status = .Playback
        //print("started playback")
    }
    
    func stopPlayback() {
        guard status == .Playback else { return }
        
        cancelAutostop()
        
        sequencer.stop()
        AudioKit.stop()
        status = .Idle
        
        stopPlaybackCallback?()
        //print("stopped playback")
    }
    
    // AUTOSTOP //
    
    @objc private func doAutostop() {
        stopPlayback()
        sequencer.rewind()
    }
    
    // Called to (re)schedule an autostop that should coincide with the very end of the melody
    func scheduleAutostop() {
        cancelAutostop()
        
        let interval = (endtime - playhead).seconds
        
        if interval > 0 {
            autostop = NSTimer.scheduledTimerWithTimeInterval(
                interval,
                target: self,
                selector: #selector(AudioProcessor.doAutostop),
                userInfo: nil,
                repeats: false)
        } else {
            doAutostop()
        }
    }
    
    // Called to cancel an autostop (i.e. playback was manually stopped)
    func cancelAutostop() {
        autostop?.invalidate()
    }
    
}
