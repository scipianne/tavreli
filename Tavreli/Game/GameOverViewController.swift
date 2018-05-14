//
//  GameOverViewController.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 04.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

class GameOverViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
    
    @IBAction func startGame(_ sender: UIButton) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "gameViewController") 
            as? GameViewController {
            (UIApplication.shared.windows[0] as UIWindow).rootViewController = viewController
        }
    }

}
