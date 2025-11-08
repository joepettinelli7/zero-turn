//
//  MowerAudio.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/24/25.
//
import SwiftUI
import AVFoundation


class MowerAudioPlayer: NSObject, ObservableObject {
    
    private var player: AVAudioPlayer?

    override init() {
        super.init()
        preloadAudio()
    }
    
    /// Preload audio to make playing audio faster
    private func preloadAudio() -> Void {
        if let url = Bundle.main.url(forResource: "audio_blade_base", withExtension: "m4a") {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.5
                player?.prepareToPlay()
            } catch {
                print("Error loading audio: \(error)")
            }
        }
    }
    
    /// Play audio on loop
    func playAudio() -> Void {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.player?.play()
        }
    }
    
    /// Stop audio player
    func stop() -> Void {
        player?.stop()
    }
    
    /// Stop audio gradually
    ///
    /// - Parameters:
    ///     - fadeDuration: Number of seconds to fade sound for
    func stopGradually(fadeDuration: TimeInterval = 1.5) {
        guard let player = player, player.isPlaying else { return }
        let fadeSteps = 20
        let timePerStep = fadeDuration / Double(fadeSteps)
        let originalVolume = player.volume
        let volumeStep = originalVolume / Float(fadeSteps)
        DispatchQueue.main.async {
            var currentStep = 0
            Timer.scheduledTimer(withTimeInterval: timePerStep, repeats: true) { timer in
                guard player.isPlaying else {
                    timer.invalidate()
                    return
                }
                currentStep += 1
                player.volume = max(0, originalVolume - Float(currentStep) * volumeStep)
                if currentStep >= fadeSteps {
                    timer.invalidate()
                    player.stop()
                    player.currentTime = 0
                    player.volume = originalVolume
                }
            }
        }
    }
    
    /// Set volume as function of mower speed
    ///
    /// - Parameters:
    ///     - mowerSpeed: Mower speed in scene
    func setVolume(mowerSpeed: CGFloat) -> Void {
        player?.volume = max(Float(mowerSpeed), 0.2)
    }
}


//class MowerAudioEngine: NSObject, ObservableObject {
//    
//    private let audioQueue = DispatchQueue(label: "com.zeroTurn.audioQueue", qos: .userInitiated)
//    private let engine = AVAudioEngine()
//    private let noBladeNode = AVAudioPlayerNode()
//    private let baseBladeNode = AVAudioPlayerNode()
//    private let startBladeNode = AVAudioPlayerNode()
//    private let stopBladeNode = AVAudioPlayerNode()
//    private var noBladeBuffer: AVAudioPCMBuffer?
//    private var baseBladeBuffer: AVAudioPCMBuffer?
//    private var startBladeBuffer: AVAudioPCMBuffer?
//    private var stopBladeBuffer: AVAudioPCMBuffer?
//    private let mixer: AVAudioMixerNode
//    
//    override init() {
//        mixer = engine.mainMixerNode
//        super.init()
//        setupAudioSession()
//        setupEngine()
//        preloadAudio()
//    }
//    
//    private func setupAudioSession() -> Void {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("Error setting up audio session: \(error)")
//        }
//    }
//    
//    private func setupEngine() -> Void {
//        engine.attach(noBladeNode)
//        engine.attach(baseBladeNode)
//        engine.attach(startBladeNode)
//        engine.attach(stopBladeNode)
//        // Connect players to the main mixer
//        engine.connect(noBladeNode, to: mixer, format: nil)
//        engine.connect(baseBladeNode, to: mixer, format: nil)
//        engine.connect(startBladeNode, to: mixer, format: nil)
//        engine.connect(stopBladeNode, to: mixer, format: nil)
//        do {
//            try engine.start()
//                engine.prepare()
//        } catch {
//            print("Error starting AVAudioEngine: \(error)")
//        }
//    }
//    
//    private func preloadAudio() -> Void {
//        if let noBladeURL = Bundle.main.url(forResource: "audio_no_blade", withExtension: "m4a") {
//            noBladeBuffer = loadAudioFile(url: noBladeURL)
//        }
//        if let baseBladeURL = Bundle.main.url(forResource: "audio_blade_base", withExtension: "m4a") {
//            baseBladeBuffer = loadAudioFile(url: baseBladeURL)
//        }
//        if let startBladeURL = Bundle.main.url(forResource: "audio_blade_start", withExtension: "m4a") {
//            startBladeBuffer = loadAudioFile(url: startBladeURL)
//        }
//        if let stopBladeURL = Bundle.main.url(forResource: "audio_blade_stop", withExtension: "m4a") {
//            stopBladeBuffer = loadAudioFile(url: stopBladeURL)
//        }
//    }
//    
//    private func loadAudioFile(url: URL) -> AVAudioPCMBuffer? {
//        do {
//            let file = try AVAudioFile(forReading: url)
//            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
//                                                frameCapacity: AVAudioFrameCount(file.length)) else { return nil }
//            try file.read(into: buffer)
//            return buffer
//        } catch {
//            print("Error loading audio file: \(error)")
//            return nil
//        }
//    }
//    
//    func playNoBladeLoop() -> Void {
//        guard let noBladeBuffer = noBladeBuffer else { return }
//        noBladeNode.stop()
//        noBladeNode.volume = 0.3
//        noBladeNode.scheduleBuffer(noBladeBuffer, at: nil, options: [.loops])
//        noBladeNode.play()
//    }
//    
//    private func stopNoBladeLoop() {
//        noBladeNode.stop()
//    }
//    
//    private func playBaseBladeLoop() -> Void {
//        guard let baseBladeBuffer = baseBladeBuffer else { return }
//        baseBladeNode.stop()
//        baseBladeNode.volume = 0.7
//        baseBladeNode.scheduleBuffer(baseBladeBuffer, at: nil, options: [.loops])
//        baseBladeNode.play()
//    }
//    
//    private func stopBaseBladeLoop() {
//        baseBladeNode.stop()
//    }
//    
//    func setVolume(mowerSpeed: CGFloat) {
//        let v = max(Float(mowerSpeed), 0.2)
//        noBladeNode.volume = v
//        baseBladeNode.volume = v
//        startBladeNode.volume = v
//        stopBladeNode.volume = v
//    }
//    
//    func playStopBlades() {
//        stopBaseBladeLoop()
//        // Play stop blade, then transition to no blade loop when it finishes
//        guard let stopBladeBuffer = stopBladeBuffer else { return }
//        audioQueue.async { [weak self] in
//            guard let self = self else { return }
//            stopBladeNode.stop()
//            noBladeNode.stop()
//            // Schedule the stop sound and play no blade sound when it finishes
//            stopBladeNode.scheduleBuffer(stopBladeBuffer, at: nil, options: []) { [weak self] in
//                DispatchQueue.main.async {
//                    self?.playNoBladeLoop()
//                }
//            }
//            stopBladeNode.volume = 0.5
//            stopBladeNode.play()
//        }
//    }
//    
//    func playStartBlades() {
//        stopNoBladeLoop()
//        // Play start blade, then transition to base loop when it finishes
//        guard let startBladeBuffer = startBladeBuffer else { return }
//        audioQueue.async { [weak self] in
//            guard let self = self else {return}
//            startBladeNode.stop()
//            baseBladeNode.stop()
//            // Schedule the start sound then start base blade loop when it finishes
//            startBladeNode.scheduleBuffer(startBladeBuffer, at: nil, options: []) { [weak self] in
//                DispatchQueue.main.async {
//                    self?.playBaseBladeLoop()
//                }
//            }
//            startBladeNode.volume = 0.7
//            startBladeNode.play()
//        }
//    }
//}
