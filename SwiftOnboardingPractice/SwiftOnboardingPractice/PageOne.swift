//
//  PageOne.swift
//  SwiftOnboardingPractice
//
//  Created by Breathometer on 6/28/16.
//  Copyright © 2016 KevinHou. All rights reserved.
//

import Foundation
import UIKit
import Foundation

class PageOne: UIViewController {
    
    @IBAction func getScrollPercentage(sender: AnyObject) {
        let scrollPercentageTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PageOne.update), userInfo: nil, repeats: true) // Declare the timer
        NSRunLoop.currentRunLoop().addTimer(scrollPercentageTimer, forMode: NSRunLoopCommonModes) // Impliment timer
    }
    
    func update() {
        print(PercentageScrolled.value)
    }
    
    override func viewDidLoad() {
        // View has loaded
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // After view has appeared
        
    }
    
}