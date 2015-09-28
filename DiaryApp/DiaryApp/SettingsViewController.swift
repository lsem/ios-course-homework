//
//  SettingsViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UINavigationBarDelegate {
  static let TimeAndDateCellTag = 10
  static let DateOnlyCellTag = 11
  static let NaturalLanguageSupportCellTag = 12
  static let DateTimeFormatSectionIndex = 0

  @IBOutlet weak var rightButtonItem: UIBarButtonItem?
  @IBOutlet weak var naturalLanguageSupportSwitch: UISwitch?
  
  var dateAndTimeIndexPath: NSIndexPath?
  var dateOnlyIndexPath: NSIndexPath?
  var naturalLanguageSupportIndexPath: NSIndexPath?
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    // WARNING: Order metters here
    super.viewDidLoad()
    setupDoneButton()
    resolveUIConfiguration()
    performInitialSetup()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func doneWithSettings(sender: AnyObject) {
    self.performSegueWithIdentifier("unwindToContainerVC", sender: self)
  }
  
  func performInitialSetup() {
    var showTimeAndDate = false
    var naturalLanguageSupport = false
    if ApplicationSettings.sharedInstance.loadFromLocalFileSystemStorage() {
      NSLog("Settings (re)loaded")
      showTimeAndDate = ApplicationSettings.sharedInstance.showTimeAndDate
      naturalLanguageSupport = ApplicationSettings.sharedInstance.naturalLanguageSupport
    }
    assert(dateAndTimeIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    assert(dateOnlyIndexPath != nil, "Did you forget to call resolveUIConfiguration()?")
    if showTimeAndDate {
      unCheckCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
      checkCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
    } else {
      checkCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
      unCheckCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
    }
    self.naturalLanguageSupportSwitch!.setOn(
      naturalLanguageSupport, animated: false)
  }
  
  // Makes all rows of specified section clear
  func deCheckAllRowsForSectionIndex(sectionIndex: Int) {
    let sectionLength = self.tableView.numberOfRowsInSection(sectionIndex)
    for row_idx in 0..<sectionLength {
      let indexPath = NSIndexPath(forRow: row_idx, inSection: sectionIndex)
      if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
        cell.accessoryType = UITableViewCellAccessoryType.None
      }
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
          case SettingsViewController.TimeAndDateCellTag:
            dateAndTimeIndexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
          case SettingsViewController.DateOnlyCellTag:
            dateOnlyIndexPath = NSIndexPath(forRow: row_idx, inSection: section_idx)
          case SettingsViewController.NaturalLanguageSupportCellTag:
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
  
  func notifySettingsChanged() {
    NSLog("SettingsVC: Settings have been changed: notifying observers")
    NSNotificationCenter.defaultCenter().postNotificationName("applicationSettingsChanged", object: nil)
  }

  // MARK: - Natural Language Support UISwitch
  @IBAction func naturalLanguageValueChanged(sender: AnyObject) {
    if let enabled = self.naturalLanguageSupportSwitch?.on {
      ApplicationSettings.sharedInstance.naturalLanguageSupport = enabled
      ApplicationSettings.sharedInstance.saveToLocalFileSystemStorage()
      notifySettingsChanged()
    }
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
    
    // Makes all clear, then check which was
    deCheckAllRowsForSectionIndex(SettingsViewController.DateTimeFormatSectionIndex)
    
    if self.dateAndTimeIndexPath == indexPath {
      checkCellAccessoryByIndexPath(self.dateAndTimeIndexPath!)
      ApplicationSettings.sharedInstance.showTimeAndDate = true
      notifySettingsChanged()
    } else if self.dateOnlyIndexPath == indexPath {
      checkCellAccessoryByIndexPath(self.dateOnlyIndexPath!)
      ApplicationSettings.sharedInstance.showTimeAndDate = false
      notifySettingsChanged()
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    processClickOnTableView(tableView, indexPath: indexPath)
  }
}
