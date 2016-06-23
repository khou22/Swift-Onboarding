//
//  ViewController.swift
//  SwiftOnboardingPractice
//
//  Created by Breathometer on 6/23/16.
//  Copyright © 2016 KevinHou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var KHouLogo: UIImageView!
    @IBOutlet weak var Btn: UIButton!
    @IBOutlet weak var WelcomeText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        KHouLogo.center.x = self.view.frame.width + 30  // Start off the screen
        WelcomeText.alpha = 0  // Start invisible
        
        let defaultBtnY: CGFloat = Btn.center.y  // Store
        Btn.center.y = self.view.frame.height + 30  // Start below the screen
        
        UIView.animateWithDuration(5.0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 2.0, options: [.CurveEaseInOut], animations: ({
            // Animations go here
            
            self.KHouLogo.center.x = self.view.frame.width / 2
            self.Btn.center.y = defaultBtnY
            self.WelcomeText.alpha = 1.0
            
        }), completion: { (value: Bool) in
            print("Animation complete")
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

