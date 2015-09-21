//
//  DetailViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
  
  @IBOutlet weak var detailDescriptionLabel: UILabel!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var moodSegmentedControl: UISegmentedControl!
  
  @IBAction func moodChanged(sender: AnyObject) {
    let selectedSegmentIndex = self.moodSegmentedControl.selectedSegmentIndex
    switch selectedSegmentIndex {
    case 0:
      NSLog("Sunny mood")
    case 1:
      NSLog("Rainy mood")
    case 2:
      NSLog("Cloudy mood")
    default:
      assert(false, "")
    }
  }
  
  var selectedDiaryRecord: DiaryRecord? {
    didSet {
      // Update the view.
      self.configureView()
    }
  }
  
  func configureView() {
    // Update the user interface for the detail item.
    if let diaryRecord = self.selectedDiaryRecord {
      self.title = "\(diaryRecord.creationDate)"
      if let label = self.detailDescriptionLabel {
        if let recordName = diaryRecord.recordName {
          label.text = recordName
        } else {
          label.text = "New Entry"
        }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    assert(textView != nil, "View unbound")
    assert(moodSegmentedControl != nil, "Mood segmented control unbound")
    // Do any additional setup after loading the view, typically from a nib.
    self.configureView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}

