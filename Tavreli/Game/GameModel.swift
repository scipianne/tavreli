//
//  GameModel.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 04.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import Foundation

enum Color {
    case white
    case black
}

class GameModel {
    
    var tavreli: [[TavreliPiece?]]!
    
    var networkingEngine: MultiplayerNetworking!
    
    fileprivate var castlingDone: Bool = false
    
}

extension GameModel {
    
    func moveTavrel(_ tavrel: TavreliPiece, to indexPath: IndexPath, towerMode: Bool) {
        tavrel.move(to: indexPath, towerMode: towerMode)

        if let warrior = tavrel as? Warrior {
            if (indexPath.section == 0 && warrior.player == .local) ||
                (indexPath.section == 7 && warrior.player == .remote) {
                createWarriorInDisguise(at: indexPath, warrior: warrior)
            }
        }
    }
    
    func addMove(_ move: Move) {
        let oldCoordinates = IndexPath(item: 7 - move.oldCoordinates.item,
                                       section: 7 - move.oldCoordinates.section)
        let newCoordinates = IndexPath(item: 7 - move.newCoordinates.item,
                                       section: 7 - move.newCoordinates.section)
        
        if let tavrel = tavreli[oldCoordinates.section][oldCoordinates.item] {
            moveTavrel(tavrel, to: newCoordinates, towerMode: move.towerMode)
        }
    }
    
    private func createWarriorInDisguise(at indexPath: IndexPath, warrior: Warrior) {
        let newTavrel: TavreliPiece
        
        switch warrior.disguise {
        case "archer":
            newTavrel = Archer(x: indexPath.item, y: indexPath.section, player: warrior.player, warrior.color, self)
        case "duke":
            newTavrel = Duke(x: indexPath.item, y: indexPath.section, player: warrior.player, warrior.color, self)
        case "fighter":
            newTavrel = Fighter(x: indexPath.item, y: indexPath.section, player: warrior.player, warrior.color, self)
        case "knight":
            newTavrel = Knight(x: indexPath.item, y: indexPath.section, player: warrior.player, warrior.color, self)
        case "helgi":
            newTavrel = Helgi(x: indexPath.item, y: indexPath.section, player: warrior.player, warrior.color, self)
        default:
            newTavrel = TavreliPiece(x: indexPath.item, y: indexPath.section,
                                     player: warrior.player, warrior.color, self)
        }
        
        newTavrel.warriorInDisguise = true
        newTavrel.z = warrior.z
        newTavrel.lowerPiece = warrior.lowerPiece
        newTavrel.movedBefore = warrior.movedBefore
        
        tavreli[indexPath.section][indexPath.item] = newTavrel
    }
    
    func performCastlingWithResult(with fighter: Fighter) -> Bool {
        guard let magus = findMagus(for: .local) else {
            return false
        }
        
        if castlingDone || fighter.movedBefore || magus.movedBefore ||
            fighter.indexPath.section != magus.indexPath.section {
            return false
        }
        
        let step = (fighter.indexPath.item - magus.indexPath.item) /
            abs((fighter.indexPath.item - magus.indexPath.item))
        var item = magus.indexPath.item + step
        while item != fighter.indexPath.item {
            if tavreli[fighter.indexPath.section][item] != nil {
                return false
            }
            item += step
        }
        
        let neighborIndexPath = IndexPath(item: magus.indexPath.item + step, section: magus.indexPath.section)
        for section in tavreli {
            for tavrel in section {
                if let tavrel = tavrel {
                    if tavrel.isValidMove(to: magus.indexPath, towerMode: false, for: .remote) ||
                        tavrel.isValidMove(to: neighborIndexPath, towerMode: false, for: .remote) {
                        return false
                    }
                }
            }
        }
        
        let newMagusIndexPath = IndexPath(item: magus.indexPath.item + 2 * step, section: magus.indexPath.section)
        let newFighterIndexPath = IndexPath(item: magus.indexPath.item + step, section: magus.indexPath.section)
        let magusMove = Move(oldCoordinates: magus.indexPath, newCoordinates: newMagusIndexPath, towerMode: false)
        let fighterMove = Move(oldCoordinates: fighter.indexPath, newCoordinates: newFighterIndexPath, towerMode: false)
        
        moveTavrel(magus, to: newMagusIndexPath, towerMode: false)
        moveTavrel(fighter, to: newFighterIndexPath, towerMode: false)
        networkingEngine.sendMove(magusMove)
        networkingEngine.sendMove(fighterMove)
        
        castlingDone = true
        
        return castlingDone
    }
    
}

extension GameModel {
    
    func setupField(color: Color) {
        let antiColor: Color = color == .white ? .black : .white
        
        tavreli = [
            [Fighter(x: 0, y: 0, player: .remote, antiColor, self),
             Knight(x: 1, y: 0, player: .remote, antiColor, self),
             Archer(x: 2, y: 0, player: .remote, antiColor, self),
             color == .white ? Duke(x: 3, y: 0, player: .remote, antiColor, self) :
                Magus(x: 3, y: 0, player: .remote, antiColor, self),
             color == .white ? Magus(x: 4, y: 0, player: .remote, antiColor, self) :
                Duke(x: 4, y: 0, player: .remote, antiColor, self),
             Archer(x: 5, y: 0, player: .remote, antiColor, self),
             Knight(x: 6, y: 0, player: .remote, antiColor, self),
             Fighter(x: 7, y: 0, player: .remote, antiColor, self)],
            [Warrior(x: 0, y: 1, player: .remote, antiColor, self, disguise: "fighter"),
             Warrior(x: 1, y: 1, player: .remote, antiColor, self, disguise: "knight"),
             Warrior(x: 2, y: 1, player: .remote, antiColor, self, disguise: "archer"),
             Warrior(x: 3, y: 1, player: .remote, antiColor, self, disguise: color == .white ? "duke" : "helgi"),
             Warrior(x: 4, y: 1, player: .remote, antiColor, self, disguise: color == .white ? "helgi" : "duke"),
             Warrior(x: 5, y: 1, player: .remote, antiColor, self, disguise: "archer"),
             Warrior(x: 6, y: 1, player: .remote, antiColor, self, disguise: "knight"),
             Warrior(x: 7, y: 1, player: .remote, antiColor, self, disguise: "fighter")],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [Warrior(x: 0, y: 6, player: .local, color, self, disguise: "fighter"),
             Warrior(x: 1, y: 6, player: .local, color, self, disguise: "knight"),
             Warrior(x: 2, y: 6, player: .local, color, self, disguise: "archer"),
             Warrior(x: 3, y: 6, player: .local, color, self, disguise: color == .white ? "duke" : "helgi"),
             Warrior(x: 4, y: 6, player: .local, color, self, disguise: color == .white ? "helgi" : "duke"),
             Warrior(x: 5, y: 6, player: .local, color, self, disguise: "archer"),
             Warrior(x: 6, y: 6, player: .local, color, self, disguise: "knight"),
             Warrior(x: 7, y: 6, player: .local, color, self, disguise: "fighter")],
            [Fighter(x: 0, y: 7, player: .local, color, self),
             Knight(x: 1, y: 7, player: .local, color, self),
             Archer(x: 2, y: 7, player: .local, color, self),
             color == .white ? Duke(x: 3, y: 7, player: .local, color, self) :
                Magus(x: 3, y: 7, player: .local, color, self),
             color == .white ? Magus(x: 4, y: 7, player: .local, color, self) :
                Duke(x: 4, y: 7, player: .local, color, self),
             Archer(x: 5, y: 7, player: .local, color, self),
             Knight(x: 6, y: 7, player: .local, color, self),
             Fighter(x: 7, y: 7, player: .local, color, self)]
        ]
    }
    
}

extension GameModel {
    
    func lastEaten(lastMoveTo: IndexPath) -> TavreliPiece? {
        var tavrel = tavreli[lastMoveTo.section][lastMoveTo.item]
        if tavrel == nil || tavrel?.lowerPiece == nil {
            return nil
        }
        
        while tavrel?.lowerPiece != nil {
            tavrel = tavrel?.lowerPiece
        }
        
        return tavrel
    }
    
    private func findMagus(for player: Player) -> Magus? {
        for section in tavreli {
            for tavrel in section {
                if let tavrel = tavrel, tavrel is Magus && tavrel.player == player {
                    return tavrel as? Magus
                }
            }
        }
        
        return nil
    }
    
    func isCheck(for player: Player) -> Bool {
        if let magus = findMagus(for: player) {
            for section in tavreli {
                for tavrel in section {
                    if tavrel != nil && tavrel!.isValidMove(to: magus.indexPath, towerMode: false, for: !player) {
                        return true
                    }
                }
            }
            
            return false
        }
        
        return true
    }
    
    func isPat() -> Bool {
        for section in tavreli {
            for tavrel in section {
                if let tavrel = tavrel, tavrel.hasValidMoves(for: .remote) {
                    return false
                }
            }
        }
        
        return true
    }
    
}
