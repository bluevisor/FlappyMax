import XCTest
import SpriteKit
@testable import FlappyMax

final class GameSceneTests: XCTestCase {
    var gameScene: GameScene!
    var mockView: SKView!
    
    override func setUp() {
        super.setUp()
        mockView = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        gameScene = GameScene(size: CGSize(width: 1024, height: 768))
        gameScene.scaleMode = .aspectFill
        mockView.presentScene(gameScene)
    }
    
    override func tearDown() {
        gameScene = nil
        mockView = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialGameState() {
        XCTAssertFalse(gameScene.isGameOver)
    }
    
    // MARK: - Physics Tests
    
    func testPhysicsSetup() {
        XCTAssertNotNil(gameScene.physicsWorld)
        XCTAssertEqual(gameScene.physicsWorld.gravity.dy, GameConfig.Physics.gravity)
    }
    
    // MARK: - Scene Setup Tests
    
    func testSceneSetup() {
        // Test that physics world is configured
        XCTAssertTrue(gameScene.physicsWorld.contactDelegate === gameScene)
        
        // Test that scene has the correct size
        XCTAssertEqual(gameScene.size.width, 1024)
        XCTAssertEqual(gameScene.size.height, 768)
        
        // Test that scene has the correct scale mode
        XCTAssertEqual(gameScene.scaleMode, .aspectFill)
    }
    
    // MARK: - Game Over Tests
    
    func testGameOver() {
        XCTAssertFalse(gameScene.isGameOver)
        
        // Simulate game over
        gameScene.isGameOver = true
        XCTAssertTrue(gameScene.isGameOver)
    }
}
