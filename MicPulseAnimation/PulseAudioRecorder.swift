//
//  PulseAudioRecorder.swift
//  MicPulseAnimation
//
//  Created by Jay Raval on 2024-03-17.
//

import Foundation
import AVFoundation
import Combine

class PulseAudioRecorder: NSObject {
    
    static var shared = PulseAudioRecorder()
    
    private var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder:AVAudioRecorder!
    private let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    private var timer: AnyCancellable?
    
    private let powerSubject = PassthroughSubject<Float, Never>()
    var powerPublisher: AnyPublisher<Float, Never> {
        return powerSubject.eraseToAnyPublisher()
    }
    
    var isRecording:Bool = false
    var url:URL?
    private let fileName = "sound.m4a"
    
    override init() {
        super.init()
        
        isAuthorized()
    }
    
    deinit {
        timer?.cancel()
    }
    
    private func recordSetup() {
        
        let newVideoName = getDirectory().appendingPathComponent(fileName)
        
        do {
            
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
            audioRecorder = try AVAudioRecorder(url: newVideoName, settings: self.settings)
            audioRecorder.delegate = self as AVAudioRecorderDelegate
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
            
        } catch {
            print("Recording update error:",error.localizedDescription)
        }
    }
    
    func record() {
        recordSetup()
        
        if let recorder = self.audioRecorder {
            if !isRecording {
                do {
                    try audioSession.setActive(true)
                    
                    timer = Timer.publish(every: 0.02, on: .main, in: .common)
                        .autoconnect()
                        .sink { [weak self] _ in
                            self?.updatePower()
                        }
                    
                    recorder.record()
                    isRecording = true
                } catch {
                    print("Record error:",error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func updatePower() {
        if isRecording {
            audioRecorder.updateMeters()
            powerSubject.send(audioRecorder.averagePower(forChannel: 0))
        } else {
            timer?.cancel()
        }
    }
    
    func stopRecording() {
        powerSubject.send(0)
        audioRecorder.stop()
        timer?.cancel()
        deleteFile()
        do {
            try audioSession.setActive(false)
        } catch {
            print("stop()",error.localizedDescription)
        }
    }
    
    private
    func deleteFile() {
        
        let bundle = getDirectory().appendingPathComponent(fileName)
        let manager = FileManager.default
        
        if manager.fileExists(atPath: bundle.path) {
            
            do {
                try manager.removeItem(at: bundle)
            } catch {
                print("delete()",error.localizedDescription)
            }
            
        } else {
            print("File is not exist.")
        }
    }
    
    
    private 
    func getDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    
    @discardableResult
    func isAuthorized() -> Bool {
        
        var result:Bool = false
        
        AVAudioSession.sharedInstance().requestRecordPermission { (res) in
            result = res == true ? true : false
        }
        
        return result
    }
}

extension PulseAudioRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        url = nil
        timer?.cancel()
        powerSubject.send(0)
        print("record finish")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error.debugDescription)
    }
}
