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
        XCTAssertEqual(gameScene.coinScore, 0)
        XCTAssertEqual(gameScene.burgerScore, 0)
    }
    
    // MARK: - Collectible Pattern Tests
    
    func testCollectiblePatternPositions() {
        // Test single pattern
        let singlePositions = CollectiblePattern.single.getRelativePositions()
        XCTAssertEqual(singlePositions.count, 1)
        XCTAssertEqual(singlePositions[0].x, 0)
        XCTAssertEqual(singlePositions[0].y, 0)
        
        // Test v2 pattern (vertical)
        let v2Positions = CollectiblePattern.v2.getRelativePositions()
        XCTAssertEqual(v2Positions.count, 2)
        let unit: CGFloat = DeviceType.current == .iPhone ? 80.0 : 120.0
        XCTAssertEqual(v2Positions[0].y, unit)
        XCTAssertEqual(v2Positions[1].y, -unit)
        
        // Test triangle pattern
        let trianglePositions = CollectiblePattern.triangle.getRelativePositions()
        XCTAssertEqual(trianglePositions.count, 3)
    }
    
    // MARK: - Stamina Tests
    
    func testStaminaManagement() {
        let initialStamina = gameScene.currentStamina
        XCTAssertEqual(initialStamina, gameScene.maxStamina)
        
        // Simulate flap
        gameScene.touchesBegan(Set<UITouch>(), with: nil)
        XCTAssertLessThan(gameScene.currentStamina, initialStamina)
        
        // Test burger restoration
        let beforeStamina = gameScene.currentStamina
        gameScene.currentStamina = gameScene.maxStamina
        XCTAssertEqual(gameScene.currentStamina, gameScene.maxStamina)
    }
    
    // MARK: - Collision Tests
    
    func testCollisionWithObstacle() {
        XCTAssertFalse(gameScene.isGameOver)
        
        // Simulate collision with obstacle
        let contact = SKPhysicsContact()
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        
        bodyA.categoryBitMask = PhysicsCategory.player
        bodyB.categoryBitMask = PhysicsCategory.obstacle
        
        // Use reflection to set private properties of SKPhysicsContact
        if let contactClass = object_getClass(contact) {
            var bodyAValue = bodyA
            var bodyBValue = bodyB
            object_setInstanceVariable(contact, "bodyA", &bodyAValue)
            object_setInstanceVariable(contact, "bodyB", &bodyBValue)
        }
        
        gameScene.didBegin(contact)
        XCTAssertTrue(gameScene.isGameOver)
    }
    
    // MARK: - Score Tests
    
    func testScoreIncrement() {
        let initialCoinScore = gameScene.coinScore
        let initialBurgerScore = gameScene.burgerScore
        
        // Simulate coin collection
        let contact = SKPhysicsContact()
        let bodyA = SKPhysicsBody()
        let bodyB = SKPhysicsBody()
        
        bodyA.categoryBitMask = PhysicsCategory.player
        bodyB.categoryBitMask = PhysicsCategory.collectible
        
        let coin = Coin()
        bodyB.node = coin
        
        // Use reflection to set private properties
        if let contactClass = object_getClass(contact) {
            var bodyAValue = bodyA
            var bodyBValue = bodyB
            object_setInstanceVariable(contact, "bodyA", &bodyAValue)
            object_setInstanceVariable(contact, "bodyB", &bodyBValue)
        }
        
        gameScene.didBegin(contact)
        XCTAssertEqual(gameScene.coinScore, initialCoinScore + 1)
        XCTAssertEqual(gameScene.burgerScore, initialBurgerScore)
    }
}
