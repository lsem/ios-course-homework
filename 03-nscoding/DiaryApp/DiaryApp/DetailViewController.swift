//
//  DetailViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

  static let SunnyMoodColor = UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
  static let RainyMoodColor = UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
  static let CloudyMoodColor = UIColor(red: 0.4, green: 0.4, blue: 0.8, alpha: 1.0)
  static let NeutralMoodColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  static let SunnyMoodSegmentIndex = 0
  static let RainyMoodSegmentIndex = 1
  static let CloudyMoodSegmentIndex = 2
  static let NoSetMoodSegmentIndex = UISegmentedControlNoSegment
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var moodSegmentedControl: UISegmentedControl!
  @IBOutlet weak var recordNameTextEdit: UITextField!
  
  var selectedDiaryRecord: DiaryRecord?
  var lastSelectedIndex: Int = UISegmentedControlNoSegment

  var detailItem: AnyObject? {
    didSet {
      self.configureView()
    }
  }
  
  @IBAction func recordNameEditingChanged(sender: AnyObject) {
    if self.selectedDiaryRecord != nil && self.recordNameTextEdit.text != nil {
      self.selectedDiaryRecord!.name = self.recordNameTextEdit.text!
      NSNotificationCenter.defaultCenter().postNotificationName("ChangeDetail", object: self.selectedDiaryRecord!)
    }
  }
  
  // Called once segmented control (self.moodSegmentedControl) value is changed.
  @IBAction func moodChanged(sender: AnyObject) {
    let selectedIndex = self.moodSegmentedControl.selectedSegmentIndex
    if self.lastSelectedIndex == selectedIndex {
      if let record = self.selectedDiaryRecord {
        record.mood = RecordMood.NoSet
        self.updateMoodUIState()
      }
    } else {
      switch selectedIndex {
      case DetailViewController.SunnyMoodSegmentIndex:
        self.selectedDiaryRecord?.mood = RecordMood.Good
      case DetailViewController.RainyMoodSegmentIndex:
        self.selectedDiaryRecord?.mood = RecordMood.Bad
      case DetailViewController.CloudyMoodSegmentIndex:
        self.selectedDiaryRecord?.mood = RecordMood.Neutral
      case DetailViewController.NoSetMoodSegmentIndex:
        () // Do nothing here
      default:
        assert(false, "Logic Error: Invalid index")
      }
      self.lastSelectedIndex = selectedIndex
      self.self.updateMoodUIState()
    }
  }
  
  func configureView() {
    self.setupUIForSelectedDiaryRecord()
    self.updateMoodUIState()
  }
  
  // Keep here setting up UI elements for selected diary record
  func setupUIForSelectedDiaryRecord() {
    if let selectedRecord = self.selectedDiaryRecord {
      self.title = DiaryRecordViewFormatter.recordPageTitle(selectedRecord)
      self.recordNameTextEdit.text = DiaryRecordViewFormatter.recordNameEdit(selectedRecord)
    }
  }
  
  // Mood related view configuration according to currently selected record
  func updateMoodUIState() {
    if let record = self.selectedDiaryRecord {
      switch(record.mood) {
      case .Neutral:
        self.view.backgroundColor = DetailViewController.CloudyMoodColor
        self.moodSegmentedControl.selectedSegmentIndex = DetailViewController.CloudyMoodSegmentIndex
      case .Bad:
        self.view.backgroundColor = DetailViewController.RainyMoodColor
        self.moodSegmentedControl.selectedSegmentIndex = DetailViewController.RainyMoodSegmentIndex
      case .Good:
        self.view.backgroundColor = DetailViewController.SunnyMoodColor
        self.moodSegmentedControl.selectedSegmentIndex = DetailViewController.SunnyMoodSegmentIndex
      case .NoSet:
        self.view.backgroundColor = DetailViewController.NeutralMoodColor
        self.moodSegmentedControl.selectedSegmentIndex = DetailViewController.NoSetMoodSegmentIndex
      }
    }
  }
  
  func verifyUIAndCodeConsistency() {
    assert(textView != nil, "View unbound")
    assert(moodSegmentedControl != nil, "Mood segmented control unbound")
  }
  
  // MARK: - UIViewController
  
  override func viewWillAppear(animated: Bool) {
    self.lastSelectedIndex = self.moodSegmentedControl.selectedSegmentIndex
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.verifyUIAndCodeConsistency()
    self.configureView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

