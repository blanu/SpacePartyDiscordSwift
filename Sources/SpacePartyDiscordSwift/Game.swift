//
//  Game.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/31/20.
//

import Foundation
import Sword

protocol Game
{
    var minPlayers: UInt {get}
    var maxPlayers: UInt {get}
    
    init(shield: Shield, startMessage: Message)
    func join(user: User)
    func start()
}
