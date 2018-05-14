//
//  Volchv.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

class Knight: TavreliPiece {
    
    override var name: String {
        get {
            return "knight"
        }
    }
    
    override func isValidMove(to indexPath: IndexPath, towerMode: Bool, for player: Player) -> Bool {
        return super.isValidMove(to: indexPath, towerMode: towerMode, for: player) && isKnightValid(to: indexPath)
    }
    
}
