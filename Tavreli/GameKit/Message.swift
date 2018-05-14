//
//  Message.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 03.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

enum MessageType {
    case messageTypeRandomNumber
    case messageTypeGameBegin
    case messageTypeMove
    case messageTypeAskForTie
    case messageTypeGameOver
}

struct Move {
    let oldCoordinates: IndexPath
    let newCoordinates: IndexPath
    let towerMode: Bool
}

enum Result {
    case whitePlayerWon
    case whitePlayerLost
    case tie
}

enum LocalResult {
    case localPlayerWon
    case localPlayerLost
    case tie
}

struct Message {
    let messageType: MessageType
    var randomNumber: UInt32? = nil
    var move: Move? = nil
    var result: Result? = nil
    
    
    init(type: MessageType) {
        messageType = type
    }
    
    func archive() -> Data {
        var message = self
        return Data(bytes: &message, count: MemoryLayout<Message>.stride)
    }
    
    static func unarchive(data: Data) -> Message {
        guard data.count == MemoryLayout<Message>.stride else {
            fatalError("error in unarchiving")
        }
        
        var message: Message!
        data.withUnsafeBytes({(bytes: UnsafePointer<Message>)->Void in
            message = UnsafePointer<Message>(bytes).pointee
        })
        
        return message
    }
}
