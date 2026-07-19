import Foundation
import AVFoundation
import UIKit

/// Short synthesized blip + haptic on each detected hit.
final class ClickPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    private(set) var enabled = true

    init() {
        setupSession()
        buildBuffer()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: buffer?.format)
        try? engine.start()
        player.play()
        haptic.prepare()
    }

    private func setupSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.ambient, options: [.mixWithOthers])
        try? s.setActive(true)
    }

    private func buildBuffer() {
        let sr = 44100.0
        let dur = 0.006
        let frames = AVAudioFrameCount(sr * dur)
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames) else { return }
        buf.frameLength = frames
        let freq = 3000.0
        if let ch = buf.floatChannelData?[0] {
            for i in 0..<Int(frames) {
                let t = Double(i) / sr
                let env = exp(-t * 600)
                let sq: Double = sin(2 * .pi * freq * t) >= 0 ? 1 : -1
                ch[i] = Float(sq * env * 0.25)
            }
        }
        buffer = buf
    }

    func setEnabled(_ on: Bool) { enabled = on }

    func click() {
        guard enabled, let buf = buffer else { return }
        player.scheduleBuffer(buf, at: nil, options: .interrupts, completionHandler: nil)
        haptic.impactOccurred(intensity: 0.7)
    }
}
