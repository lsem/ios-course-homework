//
//  ApplicationSettings.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/23/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation


class ApplicationSettings : NSObject, NSCoding {
  var saveOnEachMemberUpdate = true
  
  var naturalLanguageSupport: Bool = false {
    didSet {
      if saveOnEachMemberUpdate {
        saveToLocalFileSystemStorage()
      }
    }
  }
  
  var showTimeAndDate: Bool = false {
    didSet {
      if saveOnEachMemberUpdate {
        saveToLocalFileSystemStorage()
      }
    }
  }
  
  static let sharedInstance = ApplicationSettings()
  
  override init() {
    super.init()
  }
  
  // Memberwise init
  init(naturalLanguageSupport: Bool, showTimeAndDate: Bool) {
    super.init()
    self.naturalLanguageSupport = naturalLanguageSupport
    self.showTimeAndDate = showTimeAndDate
  }
  
  // MARK: - NSCoding
  
  required convenience init?(coder decoder: NSCoder) {
    let naturalLanguageSupport = decoder.decodeBoolForKey("naturalLanguageSupport")
    let showTimeAndDate = decoder.decodeBoolForKey("showTimeAndDate")
    self.init(naturalLanguageSupport: naturalLanguageSupport, showTimeAndDate: showTimeAndDate)
  }
  
  func encodeWithCoder(coder: NSCoder) {
    coder.encodeBool(self.naturalLanguageSupport, forKey: "naturalLanguageSupport")
    coder.encodeBool(self.showTimeAndDate, forKey: "showTimeAndDate")
  }
  
}