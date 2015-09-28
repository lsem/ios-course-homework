//
//  DateEditViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/28/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit


class DateEditViewController: UIViewController {
  
  @IBOutlet weak var dateTimePicker: UIDatePicker!

  var initDate: NSDate? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(animated: Bool) {
    self.dateTimePicker.date = self.initDate!
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Do actions on segue activations
  }
  
}
