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
    
    private let cropNode = SKCropNode() // Crop and cover the shortGrassTileMap until cut
    private let cropMaskNode = SKNode() // Mask for cropNode
    private let flattenedMaskNode = SKSpriteNode() // To create single texture of all cut nodes
    private let redMaskNode = SKSpriteNode() // Mask where grass is uncut for user
    private let grassTileMap: SKTileMapNode // Uncut grass texture to remove and cover
    private let shortGrassTileMap: SKTileMapNode // Cut grass texture to expose
    private static let seed: UInt64 = getDailySeed() // New seed generated each day
    private lazy var rng = GKMersenneTwisterRandomSource(seed: Self.seed) // to generate random points
    private let ciContext = CIContext(options: [.cacheIntermediates: false]) // To make grass emitter faster
    private let areaAverageFilter = CIFilter.areaAverage() // To make grass emitter faster
    var totalCutCoverage: CGFloat = 0.0
    
    var cutCount: Int {
        return cropMaskNode.children.count
    }
    
    init (grassImage: String, shortGrassImage: String) {
        let grassTexture = SKTexture(imageNamed: grassImage)
        grassTileMap = Self.setupTileMap(texture: grassTexture, nRows: 2, nCols: 1, zPos: 0.0)
        node.addChild(grassTileMap)
        let shortGrassTexture = SKTexture(imageNamed: shortGrassImage)
        shortGrassTileMap = Self.setupTileMap(texture: shortGrassTexture, nRows: 10, nCols: 5, zPos: 1.0)
        
        cropNode.maskNode = cropMaskNode
        cropNode.addChild(shortGrassTileMap)
        cropNode.zPosition = 1.0
        node.addChild(cropNode)
        flattenedMaskNode.size = shortGrassTileMap.mapSize
        flattenedMaskNode.position = CGPoint(x: 0, y: 0)
        flattenedMaskNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cropMaskNode.addChild(flattenedMaskNode)
        
        redMaskNode.color = .red
        redMaskNode.size = shortGrassTileMap.mapSize
        redMaskNode.position = CGPoint(x: 0, y: 0)
        redMaskNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        redMaskNode.alpha = 0.4
        redMaskNode.zPosition = 1.0
        cropNode.addChild(redMaskNode)
        
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
        let components = calendar.dateComponents(in: TimeZone.current, from: date)
        let year = UInt64(components.year ?? 0)
        let month = UInt64(components.month ?? 0)
        let day = UInt64(components.day ?? 0)
        let seed = year * 10_000 + month * 100 + day
        print("Using seed: \(seed)")
        return seed
    }
    
    /// Add physics body around edge of grassTileMap so mower cannot leave
    /// that area, and cannot add cut nodes outside of this frame.
    private func updatePhysicsEdges() -> Void {
        node.physicsBody = nil
        let size = grassTileMap.mapSize
        let rect = CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        )
        let path = CGPath(rect: rect, transform: nil)
        node.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.mower
        node.physicsBody?.collisionBitMask = PhysicsCategory.mower
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
            let minSpacing = (mowerWidth + obstacleNode.size.width) * 1.3
            let size = obstacleNode.size
            let obstacleLongSide = max(size.width, size.height)
            let point = getRandomPoint(mapSize: mapSize, obstacleSize: size, minSpacing: minSpacing, prevPoints: prevPoints)
            obstacleNode.position = point
            prevPoints.append(point)
            node.addChild(obstacleNode)
            // Add cut buffer around obstacles
            cutGrass(at: obstacleNode.position, obstacleLongSide + 50, obstacleLongSide + 50)
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
    ///     - The percentage as decimal 0-1 so 1.0 if nothing cut and 0.0 if everything is cut.
    func getMowerCutCoverage(using view: SKView, at position: CGPoint, _ width: CGFloat, _ height: CGFloat) -> CGFloat {
        // If rectangle under mower deck (~136 x ~67) and only use that area for calculations.
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
        // Update total cut coverage
        updateTotalCutCoverage(using: view) { coverage in }
    }
    
    /// Update the total cut coverage of the shortGrassTileMap. Downsize
    /// the node so that calculation is faster. A value of 0.0 means
    /// nothing is cut, 1.0 means everything is cut.
    ///
    /// - Parameters:
    ///     - view: The GameScene view
    ///     - completion: Completion closure to run after
    func updateTotalCutCoverage(using view: SKView, completion: @escaping (CGFloat) -> Void) {
        // Must capture texture on main thread
        let frameInMaskSpace = flattenedMaskNode.convert(shortGrassTileMap.frame,
                                                         from: shortGrassTileMap.parent!
        )
        let renderScale: CGFloat = 0.25
        let scaledRect = CGRect(
                x: frameInMaskSpace.origin.x * renderScale,
                y: frameInMaskSpace.origin.y * renderScale,
                width: frameInMaskSpace.size.width * renderScale,
                height: frameInMaskSpace.size.height * renderScale
        )
        let smallMaskNode = flattenedMaskNode.copy() as! SKSpriteNode
        smallMaskNode.setScale(renderScale)
        guard let smallMaskTexture = view.texture(from: smallMaskNode, crop: scaledRect) else {
            completion(0)
            return
        }
        let cgImage = smallMaskTexture.cgImage()
        // Do CI processing on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            let ciImage = CIImage(cgImage: cgImage)
            self.areaAverageFilter.inputImage = ciImage
            self.areaAverageFilter.extent = ciImage.extent
            guard let outputImage = self.areaAverageFilter.outputImage else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            var pixel = [UInt8](repeating: 0, count: 4)
            self.ciContext.render(
                outputImage,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: outputImage.extent,
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )
            let totalCutCoverage = CGFloat(pixel[0]) / 255.0
            // Return the result to the main thread safely
            DispatchQueue.main.async {
                self.totalCutCoverage = totalCutCoverage
                completion(totalCutCoverage)
            }
        }
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
        updatePhysicsEdges()
    }
    
    /// Toggle visibility to highlight uncut regions
    ///
    /// - Parameters:
    ///     - visible: Whether uncut mask should be visible
    func setRedMaskHidden(_ hidden: Bool) -> Void {
        if redMaskNode.isHidden != hidden {
            redMaskNode.isHidden = hidden
        }
    }
    
    /// Toggle the visibility
    func toggleRedMaskHidden() -> Void {
        redMaskNode.isHidden = !redMaskNode.isHidden
    }
    
    /// Determine whether a rect is contained by landscape
    ///
    /// - Parameters:
    ///     - rect: The rectangle in landscape coordinates
    /// - Returns:
    ///     - True if rect is contained in landscape bounds
    func containsRect(rect: CGRect) -> Bool {
        return true
    }
}
