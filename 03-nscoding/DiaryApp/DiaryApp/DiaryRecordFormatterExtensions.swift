//
//  DiaryRecordFormatterExtensions.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/23/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation


extension DiaryRecordViewFormatter {

  func loadConfigurationFromApplicationSettings() {
    self.useRelativeDateFormatting = ApplicationSettings.sharedInstance.naturalLanguageSupport
    self.showTime = ApplicationSettings.sharedInstance.showTimeAndDate
  }
}