//
//  DetailViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

  static let SunnyMoodColor = UIColor(red: 1.0, green: 1.0, blue: 0.5, alpha: 1.0)
  static let RainyMoodColor = UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
  static let CloudyMoodColor = UIColor(red: 0.4, green: 0.4, blue: 0.8, alpha: 1.0)
  static let NeutralMoodColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  static let SunnyMoodSegmentIndex = 0
  static let RainyMoodSegmentIndex = 1
  static let CloudyMoodSegmentIndex = 2
  static let NoSetMoodSegmentIndex = UISegmentedControlNoSegment
  
  @IBOutlet weak var changeDateButton: UIButton!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var moodSegmentedControl: UISegmentedControl!
  @IBOutlet weak var recordNameTextEdit: UITextField!
  @IBOutlet weak var changeRecordDateButton: UIBarButtonItem!
  
  var recordId: Int = -1
  var lastSelectedIndex: Int = UISegmentedControlNoSegment
  
  var recordBeingEdited: DiaryRecord? { get {
      if self.recordId != -1 {
        let record = DataModel.sharedInstance.retrieveDiaryRecordByID(recordId)
        return record
      }
      return nil
    }
  }
  
  func changeRecordDate(sender: AnyObject) {
    performSegueWithIdentifier("changeRecordDateSegue", sender: self)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "changeRecordDateSegue" {
      if let nav = segue.destinationViewController as? UINavigationController {
        if let viewController = nav.topViewController as? DateEditViewController {
          if let currentRecord = self.recordBeingEdited {
            viewController.initDate =  currentRecord.creationDate
          }
        }
      }
    } else if segue.identifier == "ReturnFromDateEditingSegue" {
      NSLog("Starting ReturnFromDateEditingSegue segue")
    }
  }
  
  func updateEditedDiaryRecord(updateCb: (DiaryRecord) -> Void) {
    DataModel.sharedInstance.updateDiaryRecorByID(self.recordId,
        updateCb: { (record: DiaryRecord) -> Void in
          updateCb(record)
    })
  }
  
  var detailItem: AnyObject? {
    didSet {
      self.configureView()
    }
  }
  
  var returnKeyPressedClosure: () -> Bool = {
    return false
  }

  @IBAction func returnFromDateEditPopup_Saved(segue: UIStoryboardSegue) {
    let dateEditViewController = getViewControllerFromSegue(segue)
    let dateTimeCanclled = dateEditViewController.dateTimePicker.date
    updateEditedDiaryRecord() { $0.creationDate = dateTimeCanclled }
  }
  
  @IBAction func returnFromDateEditPopup_Cancel(segue: UIStoryboardSegue) {
    NSLog("Date record change cancelled")
  }
  
  func getViewControllerFromSegue(segue: UIStoryboardSegue) -> DateEditViewController {
    let dateEditViewController = segue.sourceViewController as! DateEditViewController
    return dateEditViewController
  }
  
  @IBAction func recordNameEditingChanged(sender: AnyObject) {
    if let newName = self.recordNameTextEdit.text {
      updateEditedDiaryRecord() { $0.name = newName }
    }
  }
  
  func subscribeOnKeyaboadNotifications() {
    let center = NSNotificationCenter.defaultCenter()
    center.addObserver(self, selector: Selector("keyboardWillShow:"), name: "UIKeyboardWillShowNotification", object: nil)
    center.addObserver(self, selector: Selector("keyboardDidShow:"), name: "UIKeyboardDidShowNotification", object: nil)
    center.addObserver(self, selector: Selector("keyboardWillHide:"), name: "UIKeyboardWillHideNotification", object: nil)
    center.addObserver(self, selector: Selector("keyboardDidHide:"), name: "UIKeyboardDidHideNotification", object: nil)    
  }
  
  func unsubscribeFromKeyboardNotifications() {
    let center = NSNotificationCenter.defaultCenter()
    center.removeObserver(self, name: "UIKeyboardWillShowNotification", object: nil)
    center.removeObserver(self, name: "UIKeyboardDidShowNotification", object: nil)
    center.removeObserver(self, name: "UIKeyboardWillHideNotification", object: nil)
    center.removeObserver(self, name: "UIKeyboardDidHideNotification", object: nil)
  }
  
  func setupRecordNameReturnKeyHandler() {
    subscribeOnReturnButtonForTextField() {
      self.activeKeyboardForRecorEditor()
      return true
    }
  }
  
  func subscribeOnReturnButtonForTextField(closure: () -> Bool) {
    self.recordNameTextEdit.delegate = self
    self.returnKeyPressedClosure = closure
  }

  func activeKeyboardForRecorEditor() {
    self.textView.becomeFirstResponder()
  }
  
  func deactiveKeyboardForRecorEditor() {
    self.textView.resignFirstResponder() 
  }
  
  // MARK: - UITextFieldDelegate methods
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    return self.returnKeyPressedClosure()
  }
  
  lazy var keybaordAccessoryViewWithDoneButton: UIView = {
    let toolbarFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 0)
    let toolbar = UIToolbar(frame: toolbarFrame)
    toolbar.items = [
      UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
      UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("doneTextViewEditing:"))
    ]
    toolbar.sizeToFit()
    return toolbar
  }()
  
  func handleKeyboardAppearanceWithSize(keyboardSize: CGRect) {
    // We want to change text view only when we edit it but not when we edit
    // record name
    if self.textView.isFirstResponder() {
      shrinkTextViewForKeyboardSize(keyboardSize)
    }
  }
  
  func doneTextViewEditing(button: UIButton?) {
    deactiveKeyboardForRecorEditor()
  }
  
  func setupKeyboardForTextViewForSize() {
    self.textView.inputAccessoryView = self.keybaordAccessoryViewWithDoneButton
    self.textView.reloadInputViews()
  }
  
  func unsetupKeyboardForTextViewForSize() {
    self.textView.inputAccessoryView = nil
    self.textView.reloadInputViews()
  }
  
  func shrinkTextViewForKeyboardSize(keyboardSize: CGRect) {
    let additionalInsetOffset: CGFloat = 20.0
    let textEnterInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + additionalInsetOffset, right: 0)
    self.textView.contentInset = textEnterInsets
  }
 
  
  // MARK: - Keybaord notifications
  
  func keyboardWillShow (notification: NSNotification) {
    if let userInfo = notification.userInfo {
      if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
        handleKeyboardAppearanceWithSize(keyboardSize)
      }
    }
  }
  
  func keyboardDidShow (note: NSNotification) {
    // Do nothing
  }
  
  func keyboardWillHide (note: NSNotification) {
    let textEnterInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    self.textView.contentInset = textEnterInsets
  }
  
  func keyboardDidHide (note: NSNotification) {
    // Do nothing
  }
  
  // MARK: - Views and actions
  
  // Called once segmented control (self.moodSegmentedControl) value is changed.
  @IBAction func moodChanged(sender: AnyObject) {
    let selectedIndex = self.moodSegmentedControl.selectedSegmentIndex
    if self.lastSelectedIndex == selectedIndex {
      updateEditedDiaryRecord() { $0.mood = RecordMood.NoSet }
      self.updateMoodUIState()
    } else {
      switch selectedIndex {
      case DetailViewController.SunnyMoodSegmentIndex:
        updateEditedDiaryRecord() { $0.mood = RecordMood.Good }
      case DetailViewController.RainyMoodSegmentIndex:
        updateEditedDiaryRecord() { $0.mood = RecordMood.Bad }
      case DetailViewController.CloudyMoodSegmentIndex:
        updateEditedDiaryRecord() { $0.mood = RecordMood.Neutral }
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
    self.textView.delegate = self
    self.setupUIForSelectedDiaryRecord()
    self.updateMoodUIState()
    self.changeDateButton.addTarget(self, action: Selector("changeRecordDate:"),
        forControlEvents: UIControlEvents.TouchUpInside)
  }
  
  // Keep here setting up UI elements for selected diary record
  func setupUIForSelectedDiaryRecord() {
    if let selectedRecord = self.recordBeingEdited {
      self.title = DiaryRecordViewFormatter.sharedInstance.recordPageTitle(selectedRecord)
      self.recordNameTextEdit.text = DiaryRecordViewFormatter.sharedInstance.recordNameEdit(selectedRecord)
      self.textView.text = selectedRecord.text
    }
  }
  
  // Mood related view configuration according to currently selected record
  func updateMoodUIState() {
    if let record = self.recordBeingEdited {
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
    verifyUIAndCodeConsistency()
    configureView()
    subscribeOnKeyaboadNotifications()
    setupRecordNameReturnKeyHandler()
    setupKeyboardForTextViewForSize()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - UITextVideDelegate
  func textViewDidChange(textView: UITextView) {
    NSLog("textViewDidChange")
    updateEditedDiaryRecord() {
      $0.text = textView.text
    }
  }
  
  
}

