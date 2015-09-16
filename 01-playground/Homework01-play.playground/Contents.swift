//: Playground - noun: a place where people can play

import UIKit

class DiaryRecord {
  let creationDate = NSDate()
  var recordName: String?
  var text: String?
  var tags: Set<String>?
  
  init() {
    
  }

  init (recordName: String, withText text: String, withTags tagsArray: [String]) {
    self.recordName = recordName
    self.text = text
    self.tags = Set<String>()
    for tag in tagsArray {
      self.tags?.insert(tag)
    }
  }
  
  init (text: String, withTags tagsArray: [String]) {
    self.text = text
    self.tags = Set<String>()
    for tag in tagsArray {
      self.tags?.insert(tag)
    }
  }

  init (tagsArray: [String]) {
    self.tags = Set<String>()
    for tag in tagsArray {
      self.tags?.insert(tag)
    }
  }
    
  init (recordName: String) {
    self.recordName = recordName
  }
  
  init (recordName: String, withText text: String) {
    self.recordName = recordName
    self.text = text
  }
  
  func fullDescription() -> String {
    var result = ""
    
    result += formatCreationDate(self.creationDate)
    
    if let recordName = self.recordName {
      result += "\n" + formatRecordName(recordName)
    }
    if let text = self.text {
      result += "\n" + formatText(text)
    }
    if let tags = self.tags {
      result += "\n" + formatTags(tags)
    }
    return result
  }
  
  /// TODO: Use NSDateFormatter class for proper formatting
  func formatCreationDate(dateValue: NSDate) -> String {
    return "\(dateValue)"
  }
  
  func formatRecordName(recordNameValue: String) -> String {
    return recordNameValue
  }
  
  func formatText(textValue: String) -> String {
    return textValue
  }
  
  func formatTags(tags: Set<String>) -> String {
    var result = ""
    if let tags = self.tags {
      result += "\n"
      var first = false
      for tag in tags {
        if !first {
          result += " "
          } else {
            first = false
          }
          result += "[\(tag)]"
        }
      }
      return result
    }
    
    } // class DiaryRecord


    // Lets play with this

    let record = DiaryRecord()
    let s = record.fullDescription()


    let recordWithTags = DiaryRecord(recordName: "First", withText: "Started learning Swift. This inconvinient convinience constructors..", withTags: ["жизнь", "боль", "swift", "strange"])

    println(recordWithTags.fullDescription())





