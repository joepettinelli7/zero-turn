//
//  LandscapeNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit
import GameplayKit
import CoreImage
import CoreImage.CIFilterBuiltins


extension CGPoint {
    
    /// Used for calculating  distance between points
    ///
    /// - Parameters:
    ///     - point: The other point to get distance to
    ///
    /// - Returns:
    ///     - The distance
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx*dx + dy*dy)
    }
}


extension GKRandomSource {
    
    /// Returns a random CGFloat in the specified closed range.
    ///
    /// - Parameters:
    ///     - range: The range for random number
    ///
    /// - Returns:
    ///     - Random number
    func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let t = CGFloat(self.nextUniform()) // 0 - 1
        return range.lowerBound + t * (range.upperBound - range.lowerBound)
    }
    
    /// Returns a random angle in radians from 0 to 2pi
    ///
    /// - Returns:
    ///     - Random angle in radians
    func nextRotation() -> CGFloat {
        return nextCGFloat(in: 0...CGFloat.pi * 2)
    }
}


class LandscapeNode {
    
    let node = SKNode()
    let moveSpeed: CGFloat = 100.0
    let offsetRot: CGFloat = CGFloat.pi / 2  // 90 degrees counter-clockwise
    let originalCenter: CGPoint
    
    private let cropNode = SKCropNode() // Crop the dirtTileMap until cut
    private let cropMaskNode = SKNode() // Mask for cropNode
    private let flattenedMaskNode = SKSpriteNode() // To create texture of all cut nodes
    private let uncutMaskNode = SKSpriteNode() // Mask where grass is uncut
    private let grassTileMap: SKTileMapNode // Uncut grass texture
    private let dirtTileMap: SKTileMapNode // Cut grass texture
    private static let seed: UInt64 = getDailySeed() // New seed generated each day
    private lazy var rng = GKMersenneTwisterRandomSource(seed: Self.seed) // to generate random points
    private let ciContext = CIContext(options: [.cacheIntermediates: false]) // To make grass emitter faster
    private let areaAverageFilter = CIFilter.areaAverage() // To make grass emitter faster
    
    var cutCount: Int {
        return cropMaskNode.children.count
    }
    
    init (grassImage: String, dirtImage: String) {
        let grassTexture = SKTexture(imageNamed: grassImage)
        grassTileMap = Self.setupTileMap(texture: grassTexture, nRows: 2, nCols: 1, zPos: 0.0)
        node.addChild(grassTileMap)
        let dirtTexture = SKTexture(imageNamed: dirtImage)
        dirtTileMap = Self.setupTileMap(texture: dirtTexture, nRows: 9, nCols: 5, zPos: 1.0)
        cropNode.maskNode = cropMaskNode
        cropNode.addChild(dirtTileMap)
        cropNode.zPosition = 1.0
        node.addChild(cropNode)
        flattenedMaskNode.position = CGPoint(x: 0, y: 0)
        flattenedMaskNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cropMaskNode.addChild(flattenedMaskNode)
        
        uncutMaskNode.color = .red
        uncutMaskNode.size = grassTileMap.mapSize
        uncutMaskNode.position = CGPoint(x: 0, y: 0)
        uncutMaskNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        uncutMaskNode.alpha = 0.4
        uncutMaskNode.zPosition = 1.0
        cropNode.addChild(uncutMaskNode)
        
        // Set originalCenter for camera node later
        let frame = node.calculateAccumulatedFrame()
        originalCenter = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    /// Setup tilemap. Make static so it can be called before
    /// initializing all non-optional properties
    ///
    /// - Parameters:
    ///     - texture: The texture to tile
    ///     - nRows: Number of rows in tilemap
    ///     - nCols: Number of cols in tilemap
    ///     - zPos: The z position of tilemap
    ///
    ///  - Returns:
    ///     - The tilemap node
    private static func setupTileMap(texture: SKTexture, nRows: Int, nCols: Int, zPos: CGFloat) -> SKTileMapNode {
        texture.filteringMode = .nearest
        let tile = SKTileDefinition(texture: texture)
        let tileGroup = SKTileGroup(tileDefinition: tile)
        let tileSet = SKTileSet(tileGroups: [tileGroup])
        let tileSize = texture.size()
        let tileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: nCols,
            rows: nRows,
            tileSize: tileSize
        )
        tileMap.zPosition = zPos
        for col in 0..<nCols {
            for row in 0..<nRows {
                tileMap.setTileGroup(tileGroup, forColumn: col, row: row)
            }
        }
        return tileMap
    }
    
    /// Get same daily seed / landscape for all users
    ///
    /// - Returns:
    ///     - The seed
    private static func getDailySeed() -> UInt64 {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        let year = UInt64(components.year ?? 0)
        let month = UInt64(components.month ?? 0)
        let day = UInt64(components.day ?? 0)
        let seed = year * 10_000 + month * 100 + day
        print("Using seed: \(seed)")
        return seed
    }
    
    /// Add obstacles to landscape
    ///
    /// - Parameters:
    ///     - count: Number of obstacles
    ///     - mowerWidth: Mower width to calculate minimum distance between obstacles
    func addObstacles(count: Int, mowerWidth: CGFloat) {
        let mapSize = grassTileMap.mapSize
        var prevPoints: [CGPoint] = [CGPoint(x: 0, y: 0)]
        for _ in 0..<count {
            let obstacleNode = getObstacle(assetName: "rock", zPos: 2.0)
            let minSpacing = (mowerWidth + obstacleNode.size.width) * 1.2
            let size = obstacleNode.size
            let point = getRandomPoint(mapSize: mapSize, obstacleSize: size, minSpacing: minSpacing, prevPoints: prevPoints)
            obstacleNode.position = point
            prevPoints.append(point)
            node.addChild(obstacleNode)
            // Add cut buffer around obstacles
            cutGrass(at: obstacleNode.position, size.width * 1.25, size.width * 1.25)
        }
    }
    
    /// Get obstacle with random size and rotation
    ///
    /// - Parameters:
    ///     - assetName: asset image name to make texture
    ///     -  zPos: The z position of the obstacle
    ///
    /// - Returns:
    ///     - The obstacle
    func getObstacle(assetName: String, zPos: CGFloat) -> SKSpriteNode {
        let obstacleTexture = SKTexture(imageNamed: "rock")
        let obstacleSize = obstacleTexture.size()
        let obstacleNode = SKSpriteNode(texture: obstacleTexture)
        let randomScale = rng.nextCGFloat(in: 0.5...1.0)
        obstacleNode.zRotation = rng.nextRotation()
        obstacleNode.setScale(randomScale)
        let scaledSize = CGSize(
            width: obstacleSize.width * randomScale,
            height: obstacleSize.height * randomScale
        )
        obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleTexture, size: scaledSize)
        obstacleNode.physicsBody?.isDynamic = false
        obstacleNode.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacleNode.physicsBody?.collisionBitMask = PhysicsCategory.mower
        obstacleNode.physicsBody?.contactTestBitMask = PhysicsCategory.mower
        obstacleNode.zPosition = zPos
        return obstacleNode
    }
    
    /// Get random position for obstacle
    ///
    /// - Parameters:
    ///     - mapSize: Grass tile map size
    ///     - obstacleSize: Obstacle size
    ///     - minSpacing: Minimum spacing alllowed between obstacles
    ///     - prevPoints: Positions of previous obstacles
    ///
    /// - Returns:
    ///     - The position to assign to obstacle
    func getRandomPoint(mapSize: CGSize, obstacleSize: CGSize, minSpacing: CGFloat, prevPoints: [CGPoint]) -> CGPoint {
        var position: CGPoint
        var attempts = 0
        let minRandomX = -mapSize.width / 2 + obstacleSize.width
        let maxRandomX = mapSize.width / 2 - obstacleSize.width
        let minRandomY = -mapSize.height / 2 + obstacleSize.height
        let maxRandomY = mapSize.height / 2 - obstacleSize.height
        repeat {
            let randomX = rng.nextCGFloat(in: minRandomX ... maxRandomX)
            let randomY = rng.nextCGFloat(in: minRandomY ... maxRandomY)
            position = CGPoint(x: randomX, y: randomY)
            attempts += 1
        } while !prevPoints.allSatisfy({ $0.distance(to: position) >= minSpacing }) && attempts < 100
        if attempts >= 100 {
            print("OBSTACLE MAX ATTEMPTS REACHED")
        }
        return position
    }
    
    /// Cut grass by changing mask node to show bottom grass node.
    /// Create an ellipse shape because mower deck is ellipse shape.
    ///
    /// - Parameters:
    ///     - position: The position of where to cut grass
    ///     - width: Width of rectangle
    ///     - height: Height of rectangle
    func cutGrass(at position: CGPoint, _ width: CGFloat, _ height: CGFloat) -> Void {
        let ovalRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let cut = SKShapeNode(ellipseIn: ovalRect)
        cut.position = position
        cut.zRotation = -node.zRotation
        cut.fillColor = .white
        cut.strokeColor = .clear
        cut.blendMode = .alpha
        cropMaskNode.addChild(cut)
    }
    
    /// Get the percentage of grass under mower deck that is cut. Use
    /// CIAreaAverage to keep data on GPU (instead of using individual pixels).
    ///
    /// - Parameters:
    ///     - view: The GameScene view
    ///     - position: The position of where to cut grass
    ///     - width: Width of rectangle
    ///     - height: Height of rectangle
    ///
    /// - Returns:
    ///     - The percentage as decimal 0-1 so 1.0 if nothing cut
    func getCutCoverage(using view: SKView, at position: CGPoint, _ width: CGFloat, _ height: CGFloat) -> CGFloat {
        // Define the rectangle under mower deck (~136 x ~67) and only use that area for calculations
        let rect = CGRect(x: position.x - (width / 2), y: position.y - (height / 2), width: width, height: height)
        guard let maskTexture = view.texture(from: flattenedMaskNode, crop: rect) else { return 0 }
        // Convert texture to CIImage for pixel access
        let cgImage = maskTexture.cgImage()
        let ciImage = CIImage(cgImage: cgImage)
        areaAverageFilter.inputImage = ciImage
        areaAverageFilter.extent = ciImage.extent
        guard let outputImage = areaAverageFilter.outputImage else { return 0 }
        var pixel = [UInt8](repeating: 0, count: 4)
        ciContext.render(outputImage,
                         toBitmap: &pixel,
                         rowBytes: 4,
                         bounds: outputImage.extent,
                         format: .RGBA8,
                         colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return 1.0 - (CGFloat(pixel[0]) / 255.0)
    }
    
    /// Add all current shape nodes in trail  to a single texture-based mask.
    /// This significantly increases performance and keeps FPS high.
    ///
    /// - Parameters:
    ///     - view: The GameScene view
    func flattenMask(using view: SKView) -> Void {
        // Temp node holds previous flattened texture
        let tempMaskNode = SKNode()
        if let texture = flattenedMaskNode.texture {
            let currentTextureNode = SKSpriteNode(texture: texture)
            currentTextureNode.size = flattenedMaskNode.size
            currentTextureNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            currentTextureNode.position = flattenedMaskNode.position
            tempMaskNode.addChild(currentTextureNode)
        }
        // Add new cuts that are not in texture yet
        for node in cropMaskNode.children where node != flattenedMaskNode {
            if let shape = node as? SKShapeNode {
                tempMaskNode.addChild(shape.copy() as! SKShapeNode)
            }
        }
        // Calculate a fixed render area based on the crop mask node
        let cropFrame = cropMaskNode.calculateAccumulatedFrame()
        guard let maskTexture = view.texture(from: tempMaskNode, crop: cropFrame) else {
            print("Failed to render cropMaskNode to texture")
            return
        }
        // Apply to flattenedMaskNode
        flattenedMaskNode.texture = maskTexture
        flattenedMaskNode.size = cropFrame.size
        flattenedMaskNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        flattenedMaskNode.position = CGPoint(x: cropFrame.midX, y: cropFrame.midY)
        // Remove all new cut nodes and add texture with all as child
        cropMaskNode.removeAllChildren()
        cropMaskNode.addChild(flattenedMaskNode)
    }
    
    /// Move and rotate the landscape node, so mower does not move
    ///
    /// - Parameters:
    ///     - moveAmount: Translation amount
    ///     - turnAmount: Rotation amount
    ///     - center: Mower node center
    ///     - cameraRotation: Camera node z rotation
    ///     - scene:  GameScene
    func moveAndRotate(moveAmount: CGFloat, turnAmount: CGFloat, center: CGPoint, cameraRotation: CGFloat, in scene: SKScene) -> Void {
        let angle: CGFloat = cameraRotation + offsetRot
        // Move the landscape
        let dx = -cos(angle) * moveAmount * moveSpeed
        let dy = -sin(angle) * moveAmount * moveSpeed
        node.position.x += dx
        node.position.y += dy
        // Rotate the landscape around mower (translate -> rotate -> translate back)
        let rotation = -turnAmount
        let currentPos = node.position
        var transform = CGAffineTransform(translationX: -center.x, y: -center.y)
        var rotatedPos = currentPos.applying(transform)
        transform = CGAffineTransform(rotationAngle: rotation)
        rotatedPos = rotatedPos.applying(transform)
        transform = CGAffineTransform(translationX: center.x, y: center.y)
        rotatedPos = rotatedPos.applying(transform)
        node.position = rotatedPos
        node.zRotation += rotation
    }
    
    /// Toggle visibibility to highlight uncut regions
    ///
    /// - Parameters:
    ///     - visible: Whether uncut mask should be visible
    func setDebugMaskVisible(_ visible: Bool) -> Void {
        uncutMaskNode.isHidden = !visible
    }
}
