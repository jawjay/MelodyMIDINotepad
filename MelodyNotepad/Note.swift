//
//  Note.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 7/23/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import Foundation
import AudioKit

class Note : NSObject, NSCoding {
    var value : MIDINoteNumber
    var onset : Double
    var duration : Double
    
    init(value : MIDINoteNumber, onset : Double, duration : Double) {
        self.value = value
        self.onset = onset
        self.duration = duration
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let value = aDecoder.decodeIntegerForKey("value")
        let onset = aDecoder.decodeDoubleForKey("onset")
        let duration = aDecoder.decodeDoubleForKey("duration")
        
        self.init(value: value,
                  onset: onset,
                  duration: duration)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(value, forKey: "value")
        aCoder.encodeDouble(onset, forKey: "onset")
        aCoder.encodeDouble(duration, forKey: "duration")
    }
    
    
    
}