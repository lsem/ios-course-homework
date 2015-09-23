//
//  DiaryRecordFormatter.swift
//  	
//
//  Created by Lyubomyr Semkiv on 9/22/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

// Encapsulated formatting needed for DiaryRecord representation in UI.
// TODO: Move it to the UI related class.
class DiaryRecordViewFormatter {
  
  static let sharedInstance = DiaryRecordViewFormatter()
  
  static let DefaultShortenedEntryName = "New Entry"
  let formatter: NSDateFormatter = NSDateFormatter()

  var useRelativeDateFormatting = false {
    didSet {
      reconfigureItself()
    }
  }
  var showTime: Bool = false {
    didSet {
      reconfigureItself()
    }
  }

  private func reconfigureItself() {
    formatter.timeStyle = NSDateFormatterStyle.ShortStyle
    formatter.dateStyle = NSDateFormatterStyle.ShortStyle
    formatter.doesRelativeDateFormatting = self.useRelativeDateFormatting
    if !self.showTime {
        formatter.timeStyle = NSDateFormatterStyle.NoStyle
    }
  }
  
  func recordNameEdit(record: DiaryRecord) -> String {
    return record.name
  }
  
  func recordMasterViewRow(record: DiaryRecord) -> (String, String) {
    if !record.name.isEmpty {
      let dateString = formatter.stringFromDate(record.creationDate)
      return (record.name, dateString)
    }
    return (DiaryRecordViewFormatter.DefaultShortenedEntryName,
      formatter.stringFromDate(record.creationDate))
  }
  
  func recordPageTitle(record: DiaryRecord) -> String {
    let dateString = formatter.stringFromDate(record.creationDate)
    return dateString
  }
}
