//
//  Melody.swif.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 7/23/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import Foundation
import AudioKit

class Melody : NSObject, NSCoding {
    var notes : [Note]
    var tempo : BPM
    var name : String
    
    
    // MARK: Archiving Paths
    // Use these paths for saving/loading melodies
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("melodies")
    
    
    init(notes : [Note] = [], tempo: Double = 120, name: String? = nil) {
        self.notes = notes
        self.tempo = tempo
        self.name = (name != nil) ? name! : Melody.generateDateString()
    }
    
    convenience init?(sequencer : AKSequencer) {
        if sequencer.tracks.count < 1 {
            return nil
        }
        
        let track = sequencer.tracks[0]
        let tempo = sequencer.tempo
        var notes : [Note] = []
        
        
        var iterator: MusicEventIterator = nil
        NewMusicEventIterator(track.internalMusicTrack, &iterator)
        
        var eventTime = MusicTimeStamp(0)
        var eventType = MusicEventType()
        var eventData: UnsafePointer<Void> = nil
        var eventDataSize: UInt32 = 0
        var hasNextEvent: DarwinBoolean = false
        
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNextEvent)
        
        while(hasNextEvent) {
            MusicEventIteratorGetEventInfo(iterator, &eventTime, &eventType, &eventData, &eventDataSize)
            
            if eventType == kMusicEventType_MIDINoteMessage {
                let data = UnsafePointer<MIDINoteMessage>(eventData)
                let note = data.memory.note
                let dur = data.memory.duration
                
                notes.append(Note(
                    value: MIDINoteNumber(note),
                    onset: Double(eventTime),
                    duration: Double(dur)
                    ))
            }
        }
        
        self.init(notes: notes, tempo: tempo)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let notes = aDecoder.decodeObjectForKey("notes") as? [Note] else {
            return nil
        }
        let tempo = aDecoder.decodeDoubleForKey("tempo")
        let name = aDecoder.decodeObjectForKey("name") as? String

        self.init(notes: notes, tempo: tempo,name:name)
    }
    
   
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(notes, forKey: "notes")
        aCoder.encodeDouble(tempo, forKey: "tempo")
        aCoder.encodeObject(name, forKey: "name")
    }
    
    
    
    func copyToTrack(track : AKMusicTrack) {
        for note in notes {
            track.add(noteNumber: note.value,
                     velocity: 127,
                     position: AKDuration(beats: note.onset),  // "tempo:" excluded to workaround AudioKit being dumb
                     duration: AKDuration(beats: note.duration))
        }
    }
    
    func duration() -> AKDuration {
        var latestNoteOff : Double = 0
        
        for note in notes {
            let noteOff = note.onset + note.duration
            if noteOff > latestNoteOff {
                latestNoteOff = noteOff
            }
        }
        
        return AKDuration(beats: latestNoteOff, tempo: tempo)
    }
    
    func join(melody : Melody) {
        self.notes.appendContentsOf(melody.notes)
        self.notes.sortInPlace({return $0.0.onset < $0.1.onset})
    }
    
    class func defaultMelody() -> Melody {
        return Melody(notes: [], tempo: 120.0)
    }
    
    class func yankeeDoodle() -> Melody {
        let pitches = [60, 60, 62, 64, 60, 64, 62]
        let durs : [Double] = [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 1]
        let onsets : [Double] = [0, 0.5, 1, 1.5, 2, 2.5, 3]
        
        
        let notes = (0..<pitches.count).map({
            return Note(value: pitches[$0], onset: onsets[$0], duration: durs[$0])
        })
        
        return Melody(notes: notes, tempo: 50,name:"Yankee Doodle")
    }
    
    class func generateDateString() -> String {
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let comp = calendar.components([.Year,.Month,.Hour,.Minute], fromDate: date)

        return "\(comp.month)/\(comp.year)/\(comp.hour):\(comp.minute)"
    }
    
    
}