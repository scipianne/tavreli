//
//  GameKitHelper.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 26.04.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit
import GameKit
import RxSwift
import RxCocoa

class GameKitHelper: NSObject {
    
    static let shared = GameKitHelper()
    
    var authenticationViewController: UIViewController!
    var lastError: Error!
    
    var match: GKMatch!
    var delegate: GameKitHelperDelegate!
    
    var gameIsLoading: Bool = true
    
    fileprivate var localPlayerIsAuthenticated: Bool = false {
        didSet {
            if localPlayerIsAuthenticated && (oldValue == false || gameIsLoading) {
                readyToStartGame.onNext(())
                gameIsLoading = false
            }
        }
    }
    fileprivate var matchStarted: Bool = false
    fileprivate var enableGameCenter: Bool = true
    
    let readyToStartGame = PublishSubject<Void>()
    let presentAuthenticationViewController = PublishSubject<Void>()
    
}

extension GameKitHelper {
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        
        if localPlayer.isAuthenticated {
            localPlayerIsAuthenticated = true
            return
        }
        
        localPlayer.authenticateHandler = {[weak self] viewController, error in
            guard let `self` = self else {
                return
            }
            
            self.setLastError(error)
            
            if viewController != nil {
                self.setAuthenticationViewController(viewController)
            } else if localPlayer.isAuthenticated {
                self.enableGameCenter = true
                self.localPlayerIsAuthenticated = true
            } else {
                self.enableGameCenter = false
            }
        }
    }
    
    func setAuthenticationViewController(_ viewController: UIViewController?) {
        if (viewController != nil) {
            authenticationViewController = viewController!
            presentAuthenticationViewController.onNext(())
        }
    }
    
    func setLastError(_ error: Error?) {
        if error != nil {
            lastError = error!
            NSLog("GameKitHelper ERROR: %@", lastError.localizedDescription)
        }
    }
    
}

extension GameKitHelper: GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        let alert = UIAlertController(title: "Выберите соперника", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default) { [weak self] _ in
            viewController.dismiss(animated: false, completion: nil)
            self?.readyToStartGame.onNext(())
        })

        viewController.present(alert, animated: true, completion: nil)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion: nil)
        NSLog("Error finding match: %@", error.localizedDescription)
    }
    
    func findMatch(viewController: UIViewController, delegate: GameKitHelperDelegate, completion: (()->Void)?) {
        if !enableGameCenter {
            return
        }
        
        matchStarted = false
        match = nil
        self.delegate = delegate
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        
        if let matchmakerViewController = GKMatchmakerViewController(matchRequest: request) {
            matchmakerViewController.matchmakerDelegate = self
            viewController.present(matchmakerViewController, animated: true, completion: completion)
        }
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        self.match = match
        match.delegate = self
        if (!matchStarted && match.expectedPlayerCount == 0) {
            NSLog("Ready to start match!")
            matchStarted = true
            delegate.matchStarted()
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if self.match != match { return }
        
        delegate.match(match, didReceive: data, fromRemotePlayer: player)
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if self.match != match { return }
        
        switch state {
        case .stateConnected:
            NSLog("Player connected!")
            
            if !matchStarted && match.expectedPlayerCount == 0 {
                NSLog("Ready to start match!")
                matchStarted = true
                delegate.matchStarted()
            }
        case .stateDisconnected:
            NSLog("Player disconnected!")
            
            matchStarted = false
            delegate?.matchEnded()
        default:
            break
        }
    }
    
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if self.match != match { return }
        
        if let error = error {
            NSLog("Failed with error %@", error.localizedDescription)
        }
        matchStarted = false
        delegate.matchEnded()
    }
    
}
