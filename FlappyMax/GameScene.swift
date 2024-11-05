import SpriteKit

class GameScene: SKScene {
    // MARK: - Properties
    private var backgroundNodes: [SKSpriteNode] = []
    private var floorNodes: [SKSpriteNode] = []
    private let backgroundSpeed: CGFloat = 150.0
    private let floorSpeed: CGFloat = 300.0

    override func didMove(to view: SKView) {
        self.scaleMode = .aspectFill
        setupBackground()
        setupFloor()
    }
    
    private func setupBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        backgroundTexture.filteringMode = .nearest

        for i in 0..<2 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.size = self.size
            background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            background.position = CGPoint(x: CGFloat(i) * self.size.width, y: frame.midY)
            background.zPosition = -1
            addChild(background)
            backgroundNodes.append(background)
        }
    }

    private func setupFloor() {
        let floorTexture = SKTexture(imageNamed: "floor")
        floorTexture.filteringMode = .nearest

        // Calculate the number of floor tiles required to cover the screen width plus one extra tile for looping
        let floorScale: CGFloat = 8.0
        let floorTileWidth = floorTexture.size().width * floorScale
        let tilesNeeded = Int(ceil(self.size.width / floorTileWidth)) + 1

        for i in 0..<tilesNeeded {
            let floor = SKSpriteNode(texture: floorTexture)
            floor.setScale(floorScale)
            floor.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            
            // Position each floor tile horizontally, starting from the leftmost position
            floor.position = CGPoint(
                x: CGFloat(i) * floorTileWidth - (floorTileWidth / 2), 
                y: frame.minY + floor.size.height / 2
            )
            
            floor.zPosition = 100
            addChild(floor)
            floorNodes.append(floor)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        moveBackground()
        moveFloor()
    }

    private func moveBackground() {
        for background in backgroundNodes {
            background.position.x -= backgroundSpeed * CGFloat(1.0/60.0)
            
            if background.position.x <= -self.size.width / 2 {
                background.position.x += self.size.width * 2
            }
        }
    }

    private func moveFloor() {
        for floor in floorNodes {
            floor.position.x -= floorSpeed * CGFloat(1.0/60.0)

            if floor.position.x <= -floor.size.width {
                floor.position.x += floor.size.width * CGFloat(floorNodes.count)
            }
        }
    }
}
