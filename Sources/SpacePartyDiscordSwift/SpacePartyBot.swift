import Foundation
import Sword
import Song

public struct SecretConfig: Codable
{
    let token: String
    let guildId: UInt64
    let clientId: String
    let channelId: UInt64
}

typealias Fact = String
typealias Facts = [Fact]

enum GameMode
{
    case none
    case spyfall(SpyfallGame)
}

public class SpacePartyBot
{
    // MARK: Properties
    let config: SecretConfig
    let shield: Shield
    var facts: Facts = []
    var state: GameMode = .none
    
    // MARK: Initializers
    public init(config: SecretConfig)
    {
        self.config = config

        let swordOptions =  SwordOptions(
            isBot: true,
            isDistributed: false,
            willCacheAllMembers: false,
            willLog: true,
            willShard: true
        )
        
        let requirements = CommandRequirements()
                
        let shieldOptions = ShieldOptions(
            prefixes: ["!", "@bot"],
            requirements: requirements,
            willBeCaseSensitive: false,
            willDefaultHelp: true,
            willIgnoreBots: true
        )
//        let shieldOptions = ShieldOptions()

        self.shield = Shield(token: config.token, swordOptions: swordOptions, shieldOptions: shieldOptions)
                
        shield.editStatus(to: "online", playing: "testing")
        
        if var helpCommand = self.shield.commands["help"]
        {
            helpCommand.options.description = "Display this help text"
            self.shield.commands["help"] = helpCommand
        }
        
        shield.register("ping", with: options("Request a Pong"), message: "Pong!")
        shield.register("pong", with: options("Request a Ping"), message: "Ping!")
        shield.register("fact", with: options("Add a fact to the fact database"), addFact)
        shield.register("facts", with: options("Show facts from the fact database"), showFacts)
        shield.register("spyfall", with: options("Start a game of Spyfall"), playSpyfall)
    }
        
    public convenience init?(path: String)
    {
        let song = SongDecoder()
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else
        {
            return nil
        }
        
        guard let secret = try? song.decode(SecretConfig.self, from: data) else
        {
            return nil
        }

        self.init(config: secret)
    }
    
    // MARK: Public functions
    public func run()
    {
        shield.connect()
    }
    
    // MARK: Commands
    func addFact(_ message: Message, _ arguments: [String])
    {
        let fact = arguments.joined(separator: " ")
        facts.append(fact)
        
        message.reply(with: "Added fact: \(fact)")
    }

    func showFacts(_ message: Message, _ arguments: [String])
    {
        var embed = Embed()
        embed.title = "Known Facts"
        
        for (index, fact) in self.facts.enumerated()
        {
            embed.addField("\(index).", value: fact)
        }
        
        message.channel.send(embed)
    }
    
    func playSpyfall(_ message: Message, _ arguments: [String])
    {
        self.state = .spyfall(SpyfallGame(shield: self.shield, startMessage: message))        
    }    
}

// MARK: Private functions
func options(_ description: String) -> CommandOptions
{
    return CommandOptions(
        aliases: [],
        description: description,
        isCaseSensitive: false,
        requirements: CommandRequirements()
    )
}

extension User: Equatable
{
    public static func == (lhs: User, rhs: User) -> Bool
    {
        return lhs.id == rhs.id
    }
}
