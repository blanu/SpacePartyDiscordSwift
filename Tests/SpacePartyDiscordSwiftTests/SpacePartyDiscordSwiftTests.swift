import XCTest
@testable import SpacePartyDiscordSwift
import Sword
import Song

final class SpacePartyDiscordSwiftTests: XCTestCase {
    func testExample() {
        guard let bot = SpacePartyBot(path: "/Users/brandon/SpacePartyDiscordSwift/secret.swift") else
        {
            XCTFail()
            return
        }
        
        bot.run()
    }
}
