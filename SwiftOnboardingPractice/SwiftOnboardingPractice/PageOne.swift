//
//  PageOne.swift
//  SwiftOnboardingPractice
//
//  Created by Breathometer on 6/28/16.
//  Copyright © 2016 KevinHou. All rights reserved.
//

import Foundation
import UIKit
// Interpolate no longer a module

class PageOne: UIViewController {
    
    // UI items
    @IBOutlet weak var dataFeedbackButton: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    
    // Gesture driven animations
    var textOpacityAnimation: Interpolate?
    var textPositionAnimation: Interpolate?
    var textRotationAnimation: Interpolate?
    
    // Constraints
    @IBOutlet weak var pageTitleConstraintX: NSLayoutConstraint!
    
    // Timer
    var scrollPercentageTimer: NSTimer?
    var feedbackOn: Bool = false
    
    @IBAction func getScrollPercentage(sender: AnyObject) {
        if !feedbackOn {
            // Set timer for feedback
            scrollPercentageTimer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(PageOne.update), userInfo: nil, repeats: true) // Declare the timer
            NSRunLoop.currentRunLoop().addTimer(scrollPercentageTimer!, forMode: NSRunLoopCommonModes) // Impliment timer
            
            dataFeedbackButton.setTitle("Stop Data Feedback", forState: .Normal) // Update label
        } else {
            // If timer isn't on
            scrollPercentageTimer?.invalidate() // Turn off timer
            
            dataFeedbackButton.setTitle("Begin Data Feedback", forState: .Normal) // Update label
        }
        feedbackOn = !feedbackOn // Set as opposite
    }
    
    func update() {
        print(PercentageScrolled.value)
        let progress: CGFloat = CGFloat(PercentageScrolled.value * 2)
        textOpacityAnimation?.progress = progress
        textPositionAnimation?.progress = progress
        textRotationAnimation?.progress = progress
    }
    
    override func viewDidLoad() {
        // View has loaded
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // After view has appeared
        
        // Set gesture drive animation
        textOpacityAnimation = Interpolate(from: 1, to: 0, apply: { [weak self] (opacity) in
            self!.pageTitle.alpha = opacity
            })
        
        textPositionAnimation = Interpolate(from: 0, to: -400, apply: { [weak self] (constant) in
            self!.pageTitleConstraintX.constant = constant
        })
        
        textRotationAnimation = Interpolate(from: 0, to: 5, apply: { [weak self] (angle) in
            self!.pageTitle.transform = CGAffineTransformMakeRotation(angle)
        })
    }
    
}