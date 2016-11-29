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
        let value = aDecoder.decodeInteger(forKey: "value")
        let onset = aDecoder.decodeDouble(forKey: "onset")
        let duration = aDecoder.decodeDouble(forKey: "duration")
        
        self.init(value: value,
                  onset: onset,
                  duration: duration)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
        aCoder.encode(onset, forKey: "onset")
        aCoder.encode(duration, forKey: "duration")
    }
    
    
    
}
