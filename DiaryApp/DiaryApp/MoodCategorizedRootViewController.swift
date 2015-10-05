//
//  MoodCategorizedRootViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 10/1/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit


class PageControllerDataSource : NSObject, UIPageViewControllerDataSource {
  var pagesDictionary: Dictionary<Int, UIViewController> = [:]
  var sourceStoryboard: UIStoryboard? = nil
  var pagesViewControllers: [UIViewController] = []
  
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
      let beforeWhichVCIndex = self.pagesViewControllers.indexOf(viewController)
      if beforeWhichVCIndex! == 0 {
        return nil
      }
      return self.pagesViewControllers[beforeWhichVCIndex! + 1]
  }

  func pageViewController(pageViewController: UIPageViewController,
    viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
      let afterWhichVCIndex = self.pagesViewControllers.indexOf(viewController)
      if afterWhichVCIndex! == 1 {
        return nil
      }
      return self.pagesViewControllers[afterWhichVCIndex! + 1]
  }
  
  private func createPagesControllers() {
    pagesViewControllers.append(createMoodSpecificController())
    pagesViewControllers.append(createMoodSpecificController())
  }
  
  private func createMoodSpecificController() -> UIViewController {
    return self.sourceStoryboard!
      .instantiateViewControllerWithIdentifier("MoodSpecificTableViewController")
  }

  func viewControllerForPageIndex(page: Int) -> UIViewController? {
    return self.pagesViewControllers[page]
  }
}


class MoodCategorizedRootViewController : UIViewController, UIPageViewControllerDelegate  {
  var pagesDataSource: PageControllerDataSource? = nil
  var pageController: UIPageViewController? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    NSLog("MoodCategorizedRootViewController: View Did Load")
    initializePageViewController()
  }
  
  // Prepares page view controller. Creates it, assotiates with delegate and data source.
  private func initializePageViewController() {
    self.pageController = UIPageViewController(transitionStyle: .Scroll,
      navigationOrientation: .Horizontal,
      options: nil)
    self.pageController!.delegate = self
    
    // Initialize data source for pages view controller
    let storyboard = self.storyboard!
    // We give data source storyboard instance to allow it instantiate classes defined in storyboard
    self.pagesDataSource = PageControllerDataSource(sourceStoryboard: storyboard)
    
    // We need to select some view controller as initial.
    let startingViewController = self.pagesDataSource!.viewControllerForPageIndex(0)!
    self.pageController!.setViewControllers([startingViewController],
      direction: .Forward, animated: false, completion: { done in })
    
    self.addChildViewController(self.pageController!)
    self.view.addSubview(self.pageController!.view)
    
    self.pageController!.dataSource = self.pagesDataSource
    self.pageController!.didMoveToParentViewController(self)
  }
}
