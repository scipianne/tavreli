//
//  MultiplayerNetworking.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 02.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit
import GameKit
import RxSwift

enum GameState: Int {
    case gameStateWaitingForMatch = 0
    case gameStateWaitingForRandomNumber
    case gameStateWaitingForStart
    case gameStateActive
    case gameStateDone
}

class MultiplayerNetworking {
    
    fileprivate var localRandomNumber: UInt32
    fileprivate var receivedRandomNumber: UInt32!
    fileprivate var isWhitePlayer: Bool! = false
    
    var gameState: GameState
    
    fileprivate weak var localPlayerColor: PublishSubject<Color>!
    fileprivate weak var otherPlayerMove: PublishSubject<Move>!
    fileprivate weak var gameEndWithResult: PublishSubject<LocalResult>!
    fileprivate weak var askedForTie: PublishSubject<Void>!
    fileprivate var bag = DisposeBag()
    
    
    init(localPlayerColor: PublishSubject<Color>, otherPlayerMove: PublishSubject<Move>,
         gameEndWithResult: PublishSubject<LocalResult>, askedForTie: PublishSubject<Void>) {
        localRandomNumber = arc4random()
        gameState = .gameStateWaitingForMatch
        
        self.localPlayerColor = localPlayerColor
        self.otherPlayerMove = otherPlayerMove
        self.gameEndWithResult = gameEndWithResult
        self.askedForTie = askedForTie
    }
    
}

extension MultiplayerNetworking: GameKitHelperDelegate {
    
    func matchStarted() {
        NSLog("started")
        if receivedRandomNumber != nil {
            gameState = .gameStateWaitingForStart;
        } else {
            gameState = .gameStateWaitingForRandomNumber;
        }
        sendRandomNumber()
        tryStartGame()
    }
    
    func matchEnded() {
        NSLog("ended")
        gameState = .gameStateDone
        GameKitHelper.shared.delegate = nil
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        let message: Message = Message.unarchive(data: data)
        if message.messageType == .messageTypeRandomNumber {
            let receivedNumber = message.randomNumber!
            NSLog("received random number %d", receivedNumber)
            
            var tie: Bool = false
            if receivedNumber == localRandomNumber {
                NSLog("TIE")
                tie = true
                localRandomNumber = arc4random()
                sendRandomNumber()
            } else {
                receivedRandomNumber = receivedNumber
            }
            
            if !tie {
                isWhitePlayer = isLocalPlayerWhite()
                if gameState == .gameStateWaitingForRandomNumber {
                    gameState = .gameStateWaitingForStart
                }
                tryStartGame()
            }
        } else if message.messageType == .messageTypeGameBegin {
            NSLog("Begin game message received");
            gameState = .gameStateActive;
            localPlayerColor.onNext(isLocalPlayerWhite() ? .white : .black)
        } else if message.messageType == .messageTypeMove {
            NSLog("Move message received");
            if let move = message.move {
                otherPlayerMove.onNext(move)
            }
        } else if message.messageType == .messageTypeAskForTie {
            askedForTie.onNext(())
        } else if message.messageType == .messageTypeGameOver {
            NSLog("Game over message received");
            if let result = message.result {
                let localResult: LocalResult
                switch result {
                case .whitePlayerWon:
                    localResult = isLocalPlayerWhite() ? .localPlayerWon : .localPlayerLost
                case .whitePlayerLost:
                    localResult = isLocalPlayerWhite() ? .localPlayerLost : .localPlayerWon
                case .tie:
                    localResult = .tie
                }
                gameEndWithResult.onNext(localResult)
            }
        }
    }

}

extension MultiplayerNetworking {
    
    private func sendRandomNumber() {
        var message = Message(type: .messageTypeRandomNumber)
        message.randomNumber = localRandomNumber
        send(data: message.archive())
    }
    
    private func sendGameBegin() {
        let message = Message(type: .messageTypeGameBegin)
        send(data: message.archive())
    }
    
    func sendMove(_ move: Move) {
        var message = Message(type: .messageTypeMove)
        message.move = move
        send(data: message.archive())
    }
    
    func sendAskForTie() {
        let message = Message(type: .messageTypeAskForTie)
        send(data: message.archive())
    }
    
    func sendGameEnd(localResult: LocalResult) {
        var message = Message(type: .messageTypeGameOver)
        let result: Result
        switch localResult {
        case .localPlayerWon:
            result = isLocalPlayerWhite() ? .whitePlayerWon : .whitePlayerLost
        case .localPlayerLost:
            result = isLocalPlayerWhite() ? .whitePlayerLost : .whitePlayerWon
        case .tie:
            result = .tie
        }
        message.result = result
        send(data: message.archive())
    }
    
    private func send(data: Data) {
        do {
            try GameKitHelper.shared.match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            NSLog("Error sending data")
        }
    }
    
}

private extension MultiplayerNetworking {
    
    func tryStartGame() {
        if isWhitePlayer && gameState == .gameStateWaitingForStart {
            gameState = .gameStateActive
            sendGameBegin()
            localPlayerColor.onNext(.white)
        }
    }
    
    func isLocalPlayerWhite() -> Bool {
        return localRandomNumber > receivedRandomNumber
    }
    
}
