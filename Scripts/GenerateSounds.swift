import Foundation
import AVFoundation

// Create a directory for the sounds if it doesn't exist
let soundsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Haptic-Timer/Resources")

try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

// Function to generate a tick sound
func generateTickSound(frequency: Float, duration: Float, volume: Float, outputURL: URL) {
    let sampleRate: Float = 44100.0
    let channelCount: UInt32 = 1
    let bitsPerChannel: UInt32 = 16
    
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                             sampleRate: Double(sampleRate),
                             channels: channelCount,
                             interleaved: false)!
    
    let totalFrames = AVAudioFrameCount(Float(duration) * sampleRate)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
    buffer.frameLength = totalFrames
    
    let channelData = buffer.floatChannelData![0]
    
    // Generate a sine wave with harmonics for a richer sound
    for frame in 0..<Int(totalFrames) {
        let time = Float(frame) / sampleRate
        
        // Base frequency
        var value = sin(2.0 * .pi * frequency * time)
        
        // Add harmonics
        value += 0.5 * sin(4.0 * .pi * frequency * time)  // 2nd harmonic
        value += 0.25 * sin(6.0 * .pi * frequency * time) // 3rd harmonic
        
        // Normalize
        value /= 1.75
        
        // Apply envelope
        let envelope: Float
        if time < 0.01 {
            envelope = time / 0.01  // Attack
        } else if time > duration - 0.01 {
            envelope = (duration - time) / 0.01  // Release
        } else {
            envelope = 1.0  // Sustain
        }
        
        channelData[frame] = value * envelope * volume
    }
    
    // Save to file
    let file = try! AVAudioFile(forWriting: outputURL, settings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channelCount,
        AVLinearPCMBitDepthKey: bitsPerChannel,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsNonInterleaved: false
    ])
    
    try! file.write(from: buffer)
}

// Generate different tick sounds with more distinct characteristics
let sounds: [(String, Float, Float, Float)] = [
    ("tick_1s", 880.0, 0.1, 0.3),    // High pitch, short, 30% volume
    ("tick_5s", 660.0, 0.15, 0.4),   // Medium-high pitch, medium-short, 40% volume
    ("tick_10s", 440.0, 0.2, 0.5),   // Medium pitch, medium, 50% volume
    ("tick_60s", 220.0, 0.25, 0.6),  // Low pitch, longer, 60% volume
    ("tick_end", 440.0, 0.3, 0.7)    // Special ending sound, 70% volume
]

for (name, frequency, duration, volume) in sounds {
    let outputURL = soundsDir.appendingPathComponent("\(name).wav")
    generateTickSound(frequency: frequency,
                     duration: duration,
                     volume: volume,
                     outputURL: outputURL)
    print("Generated \(name).wav")
}

print("All sounds generated successfully!") 