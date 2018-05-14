//
//  GameKitHelperDelegate.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 02.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import GameKit

protocol GameKitHelperDelegate {
    
    func matchStarted()
    func matchEnded()
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer)
    
}
