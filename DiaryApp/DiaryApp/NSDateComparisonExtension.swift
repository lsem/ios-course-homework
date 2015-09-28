//
//  NSDateComparisonExtension.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/27/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation


public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
  return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
  return lhs.compare(rhs) == .OrderedAscending
}

extension NSDate: Comparable { }
