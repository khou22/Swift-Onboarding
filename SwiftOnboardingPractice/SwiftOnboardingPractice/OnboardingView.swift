//
//  OnboardingView.swift
//  SwiftOnboardingPractice
//
//  Created by Breathometer on 6/28/16.
//  Copyright © 2016 KevinHou. All rights reserved.
//

import Foundation
import UIKit

struct PercentageScrolled {
    // Global variable for percentage scrolled
    static var value: Float = 0.0
}

class OnboardingPager: UIPageViewController {
    
    func getPageOne() -> PageOne {
        // Retrieve the view
        return storyboard!.instantiateViewControllerWithIdentifier("PageOne") as! PageOne
    }
    
    func getPageTwo() -> PageTwo {
        // Retrieve page two
        return storyboard!.instantiateViewControllerWithIdentifier("PageTwo") as! PageTwo
    }
    
    func getPageThree() -> PageThree {
        // Retrieve page two
        return storyboard!.instantiateViewControllerWithIdentifier("PageThree") as! PageThree
    }
    
    override func viewDidLoad() {
        // Loads the first page immediately after the pager loads
        setViewControllers([getPageOne()], direction: .Forward, animated: false, completion: nil)
        
        // Set dataSource: incorporates the pages
        dataSource = self // Refers to the OnboardingPager extension of type UIPageViewControllerDataSource

        view.backgroundColor = .lightGrayColor() // Set background color to white
        
        
        // Scrolling progress - from: http://stackoverflow.com/questions/22577929/progress-of-uipageviewcontroller
        super.viewDidLoad()
        for subView in view.subviews {
            if subView is UIScrollView {
                (subView as! UIScrollView).delegate = self
            }
        }
    }
    
}

extension OnboardingPager: UIPageViewControllerDataSource {
    
    // ********* Sets up the page flow *********
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        // Swiping forward
        
        if viewController.isKindOfClass(PageOne) { // If you're on page one
            // We want to swipe to page two
            return getPageTwo()
        } else if viewController.isKindOfClass(PageTwo) {
            // Swipe to page three
            return getPageThree()
        } else { // If on last page
            // End of all pages
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        // Swiping backward
        
        if viewController.isKindOfClass(PageThree) {
            // Page three --> page two
            return getPageTwo()
        } else if viewController.isKindOfClass(PageTwo) {
            // If on page two, can swipe back to page one
            return getPageOne()
        } else {
            // If on the first page, can't swipe back
            return nil
        }
    }
    
    // ********* Sets up the page control dots *********
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        // The number of dots in the page control dots
        return 3
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        // On the first dot when you first load the OnboardingPager
        // Swift automatically handles switching pages and updating the page control dots
        // Updates when setViewControllers is called
        return 0
    }
}

extension OnboardingPager: UIScrollViewDelegate {
    // Track the progress of the scroll between pages
    // http://stackoverflow.com/questions/22577929/progress-of-uipageviewcontroller
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        var percentComplete: CGFloat
        percentComplete = fabs(point.x - view.frame.size.width)/view.frame.size.width // Calc percentage complete
//        print("Percent of Scroll Completed: \(percentComplete)") // Feedback
        PercentageScrolled.value = Float(percentComplete) // Update the value
    }
}