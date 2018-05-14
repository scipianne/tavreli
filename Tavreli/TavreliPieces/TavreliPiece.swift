//
//  TavreliPiece.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

enum Player {
    case local
    case remote
    
    static prefix func !(_ player: Player) -> Player {
        return player == .local ? .remote : .local
    }
}

class TavreliPiece {
    var indexPath: IndexPath
    var z: Int
    
    var lowerPiece: TavreliPiece? = nil
    var warriorInDisguise: Bool = false
    let player: Player
    var movedBefore: Bool = false
    var image: UIImage?
    var color: Color!
    
    weak var model: GameModel!
    
    var name: String {
        get {
            return ""
        }
    }
    
    
    init(x: Int, y: Int, player: Player, _ color: Color, _ model: GameModel) {
        self.indexPath = IndexPath(item: x, section: y)
        self.z = 0
        self.player = player
        self.color = color
        
        self.model = model
        
        setImage(for: color)
    }
    
    func isValidMove(to indexPath: IndexPath, towerMode: Bool, for player: Player) -> Bool {
        if self.indexPath == indexPath {
            return false
        }
        
        return self.player == player
    }
    
}

extension TavreliPiece {
    
    func move(to indexPath: IndexPath, towerMode: Bool) {
        model.tavreli[self.indexPath.section][self.indexPath.item] = towerMode ? nil : lowerPiece
        
        if var tavreliAtMove = model.tavreli[indexPath.section][indexPath.item] {
            var lastTavrel = self
            lastTavrel.indexPath = indexPath
            if towerMode {
                lastTavrel.z += tavreliAtMove.z + 1
                while lastTavrel.lowerPiece != nil {
                    lastTavrel = lastTavrel.lowerPiece!
                    lastTavrel.indexPath = indexPath
                    lastTavrel.z += tavreliAtMove.z + 1
                }
            } else {
                lastTavrel.z = tavreliAtMove.z + 1
            }
            
            if tavreliAtMove.warriorInDisguise {
                let warrior = Warrior(x: indexPath.item, y: indexPath.section, player: tavreliAtMove.player,
                                      tavreliAtMove.color, model, disguise: tavreliAtMove.name)
                warrior.lowerPiece = tavreliAtMove.lowerPiece
                warrior.z = tavreliAtMove.z
                warrior.movedBefore = tavreliAtMove.movedBefore
                
                tavreliAtMove = warrior
            }
            
            lastTavrel.lowerPiece = tavreliAtMove
        } else {
            var lastTavrel = self
            lastTavrel.indexPath = indexPath
            if towerMode {
                while lastTavrel.lowerPiece != nil {
                    lastTavrel = lastTavrel.lowerPiece!
                    lastTavrel.indexPath = indexPath
                }
            }
            
            lastTavrel.lowerPiece = nil
        }
        
        model.tavreli[indexPath.section][indexPath.item] = self
        movedBefore = true
    }
    
}

extension TavreliPiece {
    
    func setImage(for color: Color) {
        image = color == .white ? UIImage(named: name + ".png") : UIImage(named: name + "2.png")
    }
    
}

extension TavreliPiece {
    
    func isArcherValid(to indexPath: IndexPath) -> Bool {
        if abs(indexPath.section - self.indexPath.section) != abs(indexPath.item - self.indexPath.item) {
            return false
        }
        
        var x = self.indexPath.section
        var y = self.indexPath.item
        let xIncrement = (indexPath.section - self.indexPath.section) /
            abs(indexPath.section - self.indexPath.section)
        let yIncrement = (indexPath.item - self.indexPath.item) / abs(indexPath.item - self.indexPath.item)
        x += xIncrement
        y += yIncrement
        while x != indexPath.section {
            if model.tavreli[x][y] != nil {
                return false
            }
            x += xIncrement
            y += yIncrement
        }
        
        return true
    }
    
    func isFighterValid(to indexPath: IndexPath) -> Bool {
        if indexPath.section != self.indexPath.section && indexPath.item != self.indexPath.item {
            return false
        }
        
        if indexPath.section == self.indexPath.section {
            let start = min(indexPath.item, self.indexPath.item) + 1
            let end = max(indexPath.item, self.indexPath.item)
            for index in start..<end {
                if model.tavreli[indexPath.section][index] != nil {
                    return false
                }
            }
        } else {
            let start = min(indexPath.section, self.indexPath.section) + 1
            let end = max(indexPath.section, self.indexPath.section)
            for index in start..<end {
                if model.tavreli[index][indexPath.item] != nil {
                    return false
                }
            }
        }
        
        return true
    }
    
    func isKnightValid(to indexPath: IndexPath) -> Bool {
        if (abs(indexPath.section - self.indexPath.section) != 2 || abs(indexPath.item - self.indexPath.item) != 1) &&
            (abs(indexPath.section - self.indexPath.section) != 1 || abs(indexPath.item - self.indexPath.item) != 2) {
            return false
        }
        
        return true
    }
    
    func hasValidMoves(for player: Player) -> Bool {
        for x in 0..<8 {
            for y in 0..<8 {
                if isValidMove(to: IndexPath(item: x, section: y), towerMode: false, for: player) {
                    return true
                }
            }
        }
        
        return false
    }
    
}
