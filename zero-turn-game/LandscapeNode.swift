//
//  LandscapeNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit


class LandscapeNode {
    
    let node = SKNode()
    let moveSpeed: CGFloat = 100.0
    let offsetRot: CGFloat = CGFloat.pi / 2  // 90 degrees counter-clockwise
    let originalCenter: CGPoint
    var shouldFlattenTrail: Bool = false
    
    private let cropNode = SKCropNode() // Crop the dirtTileMap until cut
    private let cropMaskNode = SKNode() // Mask for cropNode
    private let flattenedMaskNode = SKSpriteNode() // To create texture of all cut nodes
    private let uncutMaskNode = SKSpriteNode() // Mask where grass is uncut
    private let grassTileMap: SKTileMapNode // Uncut grass texture
    private let dirtTileMap: SKTileMapNode // Cut grass texture
    
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
    
    /// Cut grass by changing mask node to show bottom grass node
    ///
    /// - Parameters:
    ///     - position: The position of where to cut grass
    ///     - radius: The radius of circle to leave
    func cutGrass(at position: CGPoint, radius: CGFloat) -> Void {
        let cut = SKShapeNode(circleOfRadius: radius)
        cut.position = position
        cut.fillColor = .white
        cut.strokeColor = .clear
        cut.blendMode = .alpha
        cropMaskNode.addChild(cut)
        if cropMaskNode.children.count == 100 {
            shouldFlattenTrail = true
        }
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
        shouldFlattenTrail = false
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
