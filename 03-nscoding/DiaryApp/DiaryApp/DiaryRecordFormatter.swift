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
  static let DefaultShortenedEntryName = "New Entry"
  static var useRelativeDateFormatting: Bool = Constants.UseRelativeDateFormatting {
    didSet {
      formatter.doesRelativeDateFormatting = self.useRelativeDateFormatting
    }
  }
  static var showTime: Bool = Constants.ShowTime {
    didSet {
      formatter.timeStyle = self.showTime == true ?
        NSDateFormatterStyle.ShortStyle : NSDateFormatterStyle.NoStyle
    }
  }
  
  // TODO: Find out whether we can create 'static lazy' property instead if this
  // hand-written approach.
  static var _formatter: NSDateFormatter?
  static var formatter: NSDateFormatter {
    get {
      if _formatter == nil {
        _formatter = NSDateFormatter()
        _formatter!.dateStyle = NSDateFormatterStyle.ShortStyle
        _formatter!.timeStyle = Constants.ShowTime ? NSDateFormatterStyle.ShortStyle
          : NSDateFormatterStyle.NoStyle
        _formatter!.doesRelativeDateFormatting = Constants.UseRelativeDateFormatting
      }
      return _formatter!
    }
  }
  
  static func recordNameEdit(record: DiaryRecord) -> String {
    return record.name
  }
  
  static func recordMasterViewRow(record: DiaryRecord) -> (String, String) {
    if !record.name.isEmpty {
      let dateString = formatter.stringFromDate(record.creationDate)
      return (record.name, dateString)
    }
    return (DiaryRecordViewFormatter.DefaultShortenedEntryName,
      formatter.stringFromDate(record.creationDate))
  }
  
  static func recordPageTitle(record: DiaryRecord) -> String {
    let dateString = formatter.stringFromDate(record.creationDate)
    return dateString
  }
}
