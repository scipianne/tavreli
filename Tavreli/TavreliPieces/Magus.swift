//
//  Volchv.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

class Magus: TavreliPiece {
    
    override var name: String {
        get {
            return "magus"
        }
    }
    
    override func isValidMove(to indexPath: IndexPath, towerMode: Bool, for player: Player) -> Bool {
        if abs(indexPath.section - self.indexPath.section) >= 2 || abs(indexPath.item - self.indexPath.item) >= 2 {
            return false
        }
        
        for section in model.tavreli {
            for tavrel in section where tavrel?.indexPath != self.indexPath {
                if tavrel != nil && tavrel!.isValidMove(to: indexPath, towerMode: false, for: !player) {
                    return false
                }
            }
        }
        
        return super.isValidMove(to: indexPath, towerMode: towerMode, for: player)
    }
    
}
