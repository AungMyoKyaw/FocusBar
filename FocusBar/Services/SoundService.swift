import Foundation
import AppKit
import AVFoundation

final class SoundService {
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var currentMode: AmbientSoundMode = .off
    private var currentVolume: Float = 0.35

    private final class SynthState: @unchecked Sendable {
        var mode: AmbientSoundMode = .off
        var volume: Float = 0.35
        var brownLast: Float = 0
        var rainFilter: Float = 0
        var tickSampleCounter: Int = 0
        var tickBurstRemaining: Int = 0
        var seed: UInt64 = 0x5DEECE66D
    }

    private let synthState = SynthState()

    func playChime(_ sound: ChimeSound, volume: Float = 0.7) {
        guard let name = sound.systemSoundName else { return }
        guard let nsSound = NSSound(named: NSSound.Name(name)) else {
            NSSound.beep()
            return
        }
        nsSound.volume = min(max(volume, 0), 1)
        nsSound.play()
    }

    func startAmbient(mode: AmbientSoundMode, volume: Float) {
        currentVolume = min(max(volume, 0), 1)
        synthState.volume = currentVolume
        synthState.mode = mode

        if mode == .off {
            stopAmbient()
            return
        }

        if currentMode != .off && audioEngine?.isRunning == true {
            currentMode = mode
            return
        }

        currentMode = mode
        setupAndStartEngine()
    }

    func updateAmbientVolume(_ volume: Float) {
        currentVolume = min(max(volume, 0), 1)
        synthState.volume = currentVolume
    }

    func stopAmbient() {
        currentMode = .off
        synthState.mode = .off
        audioEngine?.stop()
        if let node = sourceNode {
            audioEngine?.detach(node)
        }
        sourceNode = nil
        audioEngine = nil
    }

    private func setupAndStartEngine() {
        let engine = AVAudioEngine()
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = max(format.sampleRate, 44_100)
        let renderFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) ?? format
        let state = synthState

        let node = AVAudioSourceNode(format: renderFormat) { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frames = Int(frameCount)
            let tickInterval = Int(sampleRate)

            for buffer in ablPointer {
                guard let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for i in 0..<frames {
                    state.seed = state.seed &* 6364136223846793005 &+ 1442695040888963407
                    let white = Float(Int32(truncatingIfNeeded: state.seed >> 32)) / Float(Int32.max)
                    var sample: Float = 0

                    switch state.mode {
                    case .off:
                        sample = 0
                    case .brownNoise:
                        state.brownLast = (state.brownLast + (0.02 * white)) / 1.02
                        sample = state.brownLast * 3.2
                    case .rain:
                        state.rainFilter = state.rainFilter * 0.88 + white * 0.12
                        let droplet = (abs(white) > 0.996) ? white * 0.35 : 0
                        sample = state.rainFilter * 1.4 + droplet
                    case .swissTick:
                        state.tickSampleCounter += 1
                        if state.tickSampleCounter >= tickInterval {
                            state.tickSampleCounter = 0
                            state.tickBurstRemaining = Int(sampleRate * 0.012)
                        }
                        if state.tickBurstRemaining > 0 {
                            let env = Float(state.tickBurstRemaining) / Float(max(1, Int(sampleRate * 0.012)))
                            sample = white * env * 0.45
                            state.tickBurstRemaining -= 1
                        } else {
                            sample = 0
                        }
                    }

                    ptr[i] = max(-0.9, min(0.9, sample * state.volume * 0.35))
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: renderFormat)

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = node
        } catch {
            LoggingService.logError(.unknown("Audio engine failed to start: \(error.localizedDescription)"), context: "SoundService")
            self.audioEngine = nil
            self.sourceNode = nil
        }
    }

    deinit {
        stopAmbient()
    }
}
