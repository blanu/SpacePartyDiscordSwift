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

public class SpacePartyBot
{
    let config: SecretConfig
    let sword: Sword
    
    public init(config: SecretConfig)
    {
        self.config = config
        
        self.sword = Sword(token: config.token, options: SwordOptions(isBot: true, isDistributed: false, willCacheAllMembers: false, willLog: true, willShard: true))
        
        sword.editStatus(to: "online", playing: "testing")
        
        sword.on(.guildCreate)
        {
            data in
            
            print(data)
        }

        sword.on(.ready)
        {
            data in

            print("ready")
            print(data)

            guard let user = data as? User else
            {
                return
            }

            print(user)
        }
        
        sword.on(.messageCreate)
        {
            data in
            
            let msg = data as! Message

            if msg.content == "!ping" {
                msg.reply(with: "Pong!")
            }
        }
        
        sword.on(.guildMemberAdd)
        {
            data in
            
            print("Guild member add \(data)")
        }
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
    
    public func run()
    {
        sword.connect()
    }
}
