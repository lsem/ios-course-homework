//
//  RootViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 10/1/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class PageViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
  var pagesDictionary: Dictionary<Int, UIViewController> = [:]
  var sourceStoryboard: UIStoryboard? = nil
  
  override init() {
    super.init()
  }
  
  convenience init(sourceStoryboard: UIStoryboard) {
    self.init()
    self.sourceStoryboard = sourceStoryboard
    createPagesControllers()
  }
  
  func pageViewController(pageViewController: UIPageViewController,
    viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    NSLog("PageViewControllerDataSource: Previous Page Requested")
      return nil
  }
  func pageViewController(pageViewController: UIPageViewController,
    viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    NSLog("PageViewControllerDataSource: Next Page Requested")
    return nil
  }
  
  private func createPagesControllers() {
    // .. fill view controller in self.pagesDictionary
    let dateCategorizedVC = getCreationDateCategorizedTableViewVC()
    self.pagesDictionary[0] = dateCategorizedVC
  }
  
  
  func getCreationDateCategorizedTableViewVC() -> UITableViewController {
    let dateCatNC = self.sourceStoryboard!.instantiateViewControllerWithIdentifier("DateCatTableVC") as!
      MasterViewController
    return dateCatNC
  }

  
  func viewControllerForPageIndex(page: Int) -> UIViewController? {
    return self.pagesDictionary[page]
  }
}

// TODOTODOTODOTODOTODOTODOTODO
// REMOVE VIEW from this controleller
// TODOTODOTODOTODOTODOTODOTODO



class RootViewController: UIViewController, UIPageViewControllerDelegate {
  var pageViewController: UIPageViewController?
  var pagesDataSource: PageViewControllerDataSource?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    NSLog("RootViewController: View Did Load")
    initializePageViewController()
  }
  
  // Prepares page view controller. Creates it, assotiates with delegate and data source.
  func initializePageViewController() {
    self.pageViewController = UIPageViewController(transitionStyle: .Scroll,
      navigationOrientation: .Horizontal,
      options: nil)
    self.pageViewController!.delegate = self
    
    // Initialize data source for pages view controller
    let storyboard = self.storyboard!
    // We give data source storyboard instance to allow it instantiate classes defined in storyboard
    self.pagesDataSource = PageViewControllerDataSource(sourceStoryboard: storyboard)
    
    // We need to select some view controller as initial.
    let startingViewController = self.pagesDataSource!.viewControllerForPageIndex(0)!
    self.pageViewController!.setViewControllers([startingViewController],
      direction: .Forward, animated: false, completion: { done in })
    
    self.addChildViewController(self.pageViewController!)
    self.view.addSubview(self.pageViewController!.view)
    
    self.pageViewController!.dataSource = self.pagesDataSource
    self.pageViewController!.didMoveToParentViewController(self)
  }
  
}
