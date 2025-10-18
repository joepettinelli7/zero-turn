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
    
    private let cropNode = SKCropNode()
    private let maskNode = SKNode()
    private let grassTileMap: SKTileMapNode
    private let dirtTileMap: SKTileMapNode
    
    init (grassImage: String, dirtImage: String) {
        let grassTexture = SKTexture(imageNamed: grassImage)
        grassTileMap = Self.setupTileMap(texture: grassTexture, nRows: 9, nCols: 5, zPos: 0.0)
        node.addChild(grassTileMap)
        let dirtTexture = SKTexture(imageNamed: dirtImage)
        dirtTileMap = Self.setupTileMap(texture: dirtTexture, nRows: 1, nCols: 1, zPos: 1.0)
        cropNode.maskNode = maskNode
        cropNode.addChild(dirtTileMap)
        cropNode.zPosition = 1.0
        node.addChild(cropNode)
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
        cut.strokeColor = .red
        cut.blendMode = .alpha
        maskNode.addChild(cut)
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
}
