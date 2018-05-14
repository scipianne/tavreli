//
//  Volchv.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class Warrior: TavreliPiece {
    
    var disguise: String
    
    override var name: String {
        get {
            return "warrior"
        }
    }
    
    init(x: Int, y: Int, player: Player, _ color: Color, _ model: GameModel, disguise: String) {
        self.disguise = disguise
        
        super.init(x: x, y: y, player: player, color, model)
    }
    
    override func isValidMove(to indexPath: IndexPath, towerMode: Bool, for player: Player) -> Bool {
        if !super.isValidMove(to: indexPath, towerMode: towerMode, for: player) {
            return false
        }
        
        let tavrelAtMove = model.tavreli[indexPath.section][indexPath.item]
        let sectionDifference = player == .local ? 1 : -1
        
        let verticalMove = indexPath.item == self.indexPath.item &&
            (self.indexPath.section - indexPath.section) == sectionDifference && tavrelAtMove == nil
        let doubleVerticalMove = indexPath.item == self.indexPath.item && !movedBefore &&
            (self.indexPath.section - indexPath.section) == 2 * sectionDifference && tavrelAtMove == nil &&
            model.tavreli[indexPath.section + 1][indexPath.item] == nil
        let diagonalMove = abs(indexPath.item - self.indexPath.item) == 1 && tavrelAtMove!.player != player &&
            (self.indexPath.section - indexPath.section) == sectionDifference && tavrelAtMove != nil
        
        return verticalMove || doubleVerticalMove || diagonalMove
    }
    
}
