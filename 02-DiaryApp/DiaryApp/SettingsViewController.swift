//
//  SettingsViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

enum DateTimeViewFormat {
  case DateOnly
  case DateAndTime
}

// Provides boundary between settings page interface implementation and
// application.
protocol SettingsControllerListener : class {
  var canNaturalLanguageBeSwithOn: Bool { get }
  var canDateAndTimeBeSet: Bool  { get }
  var canDateOnlyBeSet: Bool { get }
  
  func naturalLanguageSupportConfigured(enabled: Bool)
  func dateTimeFormatChanged(format: DateTimeViewFormat)

}

extension SettingsControllerListener {
  var canNaturalLanguageBeSwithOn: Bool { return true }
  var canDateAndTimeBeSet: Bool  { return true}
  var canDateOnlyBeSet: Bool { return true }
}

class SettingsViewController: UITableViewController, UINavigationBarDelegate {
  @IBOutlet weak var rightButtonItem: UIBarButtonItem?
  @IBOutlet weak var naturalLanguageSupportSwitch: UISwitch?
  
  var dateAndTimeIndexPath: NSIndexPath?
  var dateOnlyIndexPath: NSIndexPath?
  var naturalLanguageSupportIndexPath: NSIndexPath?
  weak var settingsControllerListener: SettingsControllerListener?
  var lastDateTimeFormatValue: DateTimeViewFormat?
  
  let timeAndDateCellTag = 10
  let dateOnlyCellTag = 11
  let naturalLanguageSupportCellTag = 12
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    // WARNING: Order metters here
    super.viewDidLoad()
    self.setupDoneButton()
    self.resolveUIConfiguration()
    self.performInitialSetup()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func doneWithSettings(sender: AnyObject) {
    self.performSegueWithIdentifier("unwindToContainerVC", sender: self)
  }
  
  func performInitialSetup() {
    assert(dateAndTimeIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    assert(dateOnlyIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    self.checkCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
    self.unCheckCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
    self.updateViewFormat(DateTimeViewFormat.DateOnly)
  }
  
  func updateViewFormat(newDateFormatValue: DateTimeViewFormat) {
    assert(self.settingsControllerListener != nil, "Settings controller should be asssigned")
    if self.lastDateTimeFormatValue != newDateFormatValue {
      self.lastDateTimeFormatValue = newDateFormatValue
      self.settingsControllerListener!.dateTimeFormatChanged(newDateFormatValue)
    }
  }
  
  func resolveUIConfiguration() {
    let sectionsCount = self.tableView.numberOfSections
    for section_idx in 0..<sectionsCount  {
      let sectionLength = self.tableView.numberOfRowsInSection(section_idx)
      for row_idx in 0..<sectionLength {
        let indexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
          switch(cell.tag) {
          case timeAndDateCellTag:
            dateAndTimeIndexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
          case dateOnlyCellTag:
            dateOnlyIndexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
          case naturalLanguageSupportCellTag:
            naturalLanguageSupportIndexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
          default:
            assert(false, "Unexpected cell, please, review your table and code for inconsistency")
          }
        }
      }
    }
    assert(dateAndTimeIndexPath != nil, "Date And Time Table Cell unresolved")
    assert(dateOnlyIndexPath != nil, "Date Table Cell unresolved")
    assert(naturalLanguageSupportIndexPath != nil, "Natural Language Support Table Cell unresolved")
  }
  
  func setupDoneButton() {
    if let rightButtonItem = self.rightButtonItem {
      rightButtonItem.action = "doneWithSettings:"
      rightButtonItem.target = self
    }
  }

  // MARK: - Natural Language Support UISwitch
  @IBAction func naturalLanguageValueChanged(sender: AnyObject) {
    let enabled = self.naturalLanguageSupportSwitch?.on
    NSLog("Vallue changed!: \(enabled)")
    assert(settingsControllerListener != nil, "Settings controller listener should exist at this moment")
    self.settingsControllerListener!.naturalLanguageSupportConfigured(enabled!)
  }
  
  // MARK: - TableViewDelegate
  func checkCellAccessoryByIndexPath(indexPath: NSIndexPath) {
      self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
  }
  
  func unCheckCellAccessoryByIndexPath(indexPath: NSIndexPath) {
      self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
  }

  // Ad-hoc switch implementation.
  func processClickOnTableView(tableView: UITableView, indexPath: NSIndexPath) {
    assert(dateAndTimeIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    assert(dateOnlyIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    assert(naturalLanguageSupportIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    assert(settingsControllerListener != nil, "Settings controller listener should exist at this moment")
    
    if self.dateAndTimeIndexPath == indexPath {
      self.checkCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
      self.unCheckCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
      self.updateViewFormat(DateTimeViewFormat.DateAndTime)
    } else if self.dateOnlyIndexPath == indexPath {
      self.checkCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
      self.unCheckCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
      self.updateViewFormat(DateTimeViewFormat.DateOnly)
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self.processClickOnTableView(tableView, indexPath: indexPath)
  }
}
