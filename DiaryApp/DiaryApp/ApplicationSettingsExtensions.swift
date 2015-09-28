//
//  ApplicationSettingsExtensions.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/23/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

// TODO: Optimize unecessary loadings/saving. This could be implemented 
// by tracking actual changes.
extension ApplicationSettings {
  
  func loadFromLocalFileSystemStorage() -> Bool {
    let resotoredSettingsData: NSData? = NSUserDefaults.standardUserDefaults().objectForKey("appSettings") as? NSData
    if let resotoredSettingsData = resotoredSettingsData {
      let restoredSettingsObject: ApplicationSettings? = NSKeyedUnarchiver.unarchiveObjectWithData(resotoredSettingsData) as? ApplicationSettings
      if let restoredSettingsObject = restoredSettingsObject {
        let savedAutoSaveFlag = self.saveOnEachMemberUpdate // Disable auto-saving while we are assigning data internally
        self.saveOnEachMemberUpdate = false
        self.naturalLanguageSupport = restoredSettingsObject.naturalLanguageSupport
        self.showTimeAndDate = restoredSettingsObject.showTimeAndDate
        self.saveOnEachMemberUpdate = savedAutoSaveFlag
        NSLog("Application Settings have been Reloaded")
        return true
      }
    }
    NSLog("WARNING: Failed loading Application Settings") // This could also be First Run
    return false
  }
  
  func saveToLocalFileSystemStorage() -> Bool {
    let appSettingsToStore: ApplicationSettings = self
    let appSettingsData: NSData? = NSKeyedArchiver.archivedDataWithRootObject(appSettingsToStore)
    if let appSettingsData = appSettingsData {
      NSUserDefaults.standardUserDefaults().setObject(appSettingsData, forKey: "appSettings")
      NSLog("Application Settings have been Saved")
      return true
    }
    NSLog("ERROR: Failed saving Application Settings")
    return false
  }
  
  func loadFactorySettings() {
    self.showTimeAndDate = true
    self.naturalLanguageSupport = true
    NSLog("Factory settings loaded.")
  }
  
}

