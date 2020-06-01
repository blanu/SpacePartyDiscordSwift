//
//  Spyfall.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/31/20.
//

import Foundation
import Sword

typealias Location = String
typealias Seconds = UInt

class SpyfallGame: Game
{    
    static let locations: [Location] = [
        "Cathedral",
        "Zoom Meeting"
    ]
    
    var minPlayers: UInt = 1 // FIXME
//    var minPlayers: UInt = 3
    var maxPlayers: UInt = 8
    
    let shield: Shield
    let startMessage: Message
    var state: SpyfallState
    var location: Location
    
    required init(shield: Shield, startMessage: Message)
    {
        self.shield = shield
        self.startMessage = startMessage
        
        self.state = .joining(SpyfallJoiningState())
        self.location = SpyfallGame.locations.randomElement()!
        
        self.shield.editStatus(to: "online", playing: "Spyfall")
        
        shield.register("join", with: options("Join the current game"), joinGame)
        shield.register("start", with: options("Start the current game"), startGame)
        
        self.startMessage.reply(with: "Now accepting players for Spyfall. Say 'join' to join the game.")
    }
    
    func joinGame(_ message: Message, _ arguments: [String])
    {
        guard let user = message.author else {return}
        
        join(user: user)
    }
    
    func startGame(_ message: Message, _ arguments: [String])
    {
        start()
    }
    
    func join(user: User)
    {
        guard let username = user.username else
        {
            startMessage.reply(with: "User has no name.")
            return
        }
        
        switch state
        {
            case .joining(var joinState):
                if joinState.players.contains(user)
                {
                    startMessage.reply(with: "You have already joined the game.")
                }
                else
                {
                    joinState.players.append(user)
                    self.state = .joining(joinState)
                    startMessage.reply(with: "\(username) joined the Spyfall game.")
                }
            default:
                startMessage.reply(with: "Joining the game is not currently possible.")
        }
    }
    
    func start()
    {
        switch state
        {
            case .joining(let joinState):
                if joinState.players.count < self.minPlayers
                {
                    startMessage.reply(with: "Not enough players.")
                    return
                }
                else if joinState.players.count > self.maxPlayers
                {
                    startMessage.reply(with: "Too many players.")
                    return
                }
                else
                {
                    let started = SpyfallCountdownState(players: joinState.players)
                    self.state = .clockStarted(started)
                    
                    for player in started.players
                    {
                        shield.getDM(for: player.id)
                        {
                            (maybeDM, maybeError) in
                            
                            guard maybeError == nil else
                            {
                                return
                            }
                            
                            guard let dm = maybeDM else
                            {
                                return
                            }
                            
                            if player == started.traitor
                            {
                                dm.send("You are the spy.")
                            }
                            else
                            {
                                dm.send("The location is \(self.location)")
                            }
                        }
                    }
                    
                    shield.unregister("join")
                    shield.unregister("start")
                    
                    shield.register("accuse", with: options("Accuse someone of being the spy"), accuse)
                    shield.register("confess", with: options("Confess that you are the spy"), confess)

                    startMessage.reply(with: "The Spyfall clock has started.")
                }
            default:
                startMessage.reply(with: "Starting the game is not currently possible.")
        }
    }
    
    func accuse(_ message: Message, _ arguments: [String])
    {
        guard let prosecution = message.author else {return}
        
        switch state
        {
            case .clockStarted(let countdown):
                if countdown.blocked.contains(prosecution)
                {
                    startMessage.reply(with: "You may not accuse again until after the clock runs out.")
                }
                else
                {
                    let accusation = SpyfallAccusationState(
                        players: countdown.players,
                        traitor: countdown.traitor,
                        countdown: countdown.countdown,
                        blocked: countdown.blocked,
                        prosecution: prosecution
                    )
                    state = .clockPaused(accusation)
                    
                    startMessage.reply(with: "The Spyfall clock is stopped. Make your accusation")
                    
                    shield.unregister("accuse")
                    shield.unregister("confess")
                    
                    shield.register("convinct", with: options("Convict the accused player"), convict)
                    shield.register("acquit", with: options("Acquit the accused player"), convict)
                    
                }
            default:
                startMessage.reply(with: "The clock cannot be stopped at this time.")
        }
    }

    func convict(_ message: Message, _ arguments: [String])
    {
        switch self.state
        {
            case .clockPaused(let accusation):
                if accusation
            default:
        }
    }
    
    func acquit(_ message: Message, _ arguments: [String])
    {
        
    }

    
    func confess(_ message: Message, _ arguments: [String])
    {
        
    }
    
    func reveal(_ message: Message, _ arguments: [String])
    {
        
    }
}

enum SpyfallState
{
    case joining(SpyfallJoiningState)
    case clockStarted(SpyfallCountdownState)
    case clockPaused(SpyfallAccusationState)
    case clockEnded(User)
    case traitorGuessing
    case gameEnded
}

struct SpyfallJoiningState
{
    var players: [User]
    
    init()
    {
        players = []
    }
}

struct SpyfallCountdownState
{
    var players: [User]
    var traitor: User
    var countdown: Seconds
    var blocked: [User]
    
    init(players: [User])
    {
        self.players = players
        self.traitor = players.randomElement()!
        self.countdown = 8 * 60 // 8 minutes
        self.blocked = []
    }
    
    init(players: [User], traitor: User, countdown: Seconds, blocked: [User])
    {
        self.players = players
        self.traitor = traitor
        self.countdown = countdown
        self.blocked = blocked
    }
}

struct SpyfallAccusationState
{
    var players: [User]
    var traitor: User
    var countdown: Seconds
    var blocked: [User]
    var prosecution: User

    init(players: [User], traitor: User, countdown: Seconds, blocked: [User], prosecution: User)
    {
        self.players = players
        self.traitor = traitor
        self.countdown = countdown
        self.blocked = blocked
        self.prosecution = prosecution
    }
}
