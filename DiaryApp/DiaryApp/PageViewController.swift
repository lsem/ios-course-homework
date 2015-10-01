//
//  PageViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 10/1/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit


class PageViewController : UIPageViewController,
                           UIPageViewControllerDelegate,
                           UIPageViewControllerDataSource {
  
  
  override func viewDidLoad() {
    NSLog("PageViewController will load")
//    self.delegate = self
//    self.dataSource = self
  }
  
  func test() {
    NSLog("Test working")
  }
  
  // MARK: - UIPageViewControllerDataSource methods

  // Request for previous page view controller.
  func pageViewController(pageViewController: UIPageViewController,
    viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
      let noPage: UIViewController? = nil
      return noPage
  }

  // Request for next page view controller.
  func pageViewController(pageViewController: UIPageViewController,
    viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
      let noPage: UIViewController? = nil
      return noPage
  }
  
}