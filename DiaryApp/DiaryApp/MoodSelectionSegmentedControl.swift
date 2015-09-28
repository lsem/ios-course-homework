//
//  MoodSelectionSegmentedControl.swift
//  	
//
//  Created by Lyubomyr Semkiv on 9/22/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

  // According to: http://stackoverflow.com/questions/17652773/how-to-deselect-a-segment-in-segmented-control-button-permanently-till-its-click
class MoodSelectionSegementedControl : UISegmentedControl {
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    let previosSelectedIndex = self.selectedSegmentIndex
    super.touchesBegan(touches, withEvent: event)
    if previosSelectedIndex == self.selectedSegmentIndex {
      self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
    }
  }
}