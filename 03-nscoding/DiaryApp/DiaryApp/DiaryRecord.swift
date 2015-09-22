//
//  DiaryRecord.swift
//  	
//
//  Created by Lyubomyr Semkiv on 9/21/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

enum RecordMood : Int32 {
  case NoSet
  case Neutral
  case Good
  case Bad
}

// Represents diary record data. Should not contain any non-essential 
// methods but only data.
class DiaryRecord : NSObject, NSCoding {
  var creationDate: NSDate = NSDate()
  var name: String = ""
  var text: String = ""
  var mood: RecordMood = .NoSet
  
  override init() {
    super.init()
  }
  
  init(name: String, text: String, mood: RecordMood, creationDate: NSDate = NSDate()) {
    super.init()
    self.creationDate = creationDate
    self.name = name
    self.text = text
    self.mood = mood
  }
  
  // MARK: NSCoding
  
  required convenience init?(coder decoder: NSCoder) {
    guard
        let creationDate = decoder.decodeObjectForKey("creationDate") as? NSDate,
        let name = decoder.decodeObjectForKey("name") as? String,
        let text = decoder.decodeObjectForKey("text") as? String,
        let mood = RecordMood(rawValue: decoder.decodeInt32ForKey("moodRaw"))
    else { return nil }
    self.init(name: name, text: text, mood: mood, creationDate: creationDate)
  }
  
  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(self.creationDate, forKey: "creationDate")
    coder.encodeObject(self.name, forKey: "name")
    coder.encodeObject(self.text, forKey: "text")
    coder.encodeInt32(self.mood.rawValue, forKey: "moodRaw")
  }
}

