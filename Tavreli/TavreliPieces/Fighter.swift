//
//  Volchv.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

class Fighter: TavreliPiece {
    
    override var name: String {
        get {
            return "fighter"
        }
    }
    
    override func isValidMove(to indexPath: IndexPath, towerMode: Bool, for player: Player) -> Bool {
        return super.isValidMove(to: indexPath, towerMode: towerMode, for: player) && isFighterValid(to: indexPath)
    }
    
}
