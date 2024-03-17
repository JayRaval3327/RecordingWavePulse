//
//  ViewController.swift
//  MicPulseAnimation
//
//  Created by Jay Raval on 2024-03-17.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet weak var btnRecording: UIButton!
    @IBOutlet weak var viewMic: UIView!
    @IBOutlet weak var wave: UIView!
    @IBOutlet weak var speechTextLabel: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    private let recorder = PulseAudioRecorder.shared
    
    enum Constants {
        static let lowerLimit: Float = -100.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewMic.layer.cornerRadius = self.viewMic.layer.frame.height/2
        self.wave.layer.cornerRadius = self.wave.layer.frame.height/2
        
        self.listenToPower()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.prepareRecordingUI(allowed: recorder.isAuthorized())
        
    }
    
    
    @IBAction func didTapRecording(_ sender: Any) {
        self.manageRecording()
    }
    
    private
    func listenToPower() {
        recorder.powerPublisher
            .sink { [weak self] power in
                guard let self = self else { return }
                self.createPulse(power: power)
            }
            .store(in: &cancellables)
    }
    
    private
    func manageRecording() {
        
        if recorder.isRecording {
            recorder.stopRecording()
            self.speechTextLabel.text = "Tap on Mic button to start recording."
        } else {
            recorder.record()
            self.speechTextLabel.text = "Recording..."
        }
    }
    
    private
    func prepareRecordingUI(allowed: Bool) {
        self.btnRecording.isUserInteractionEnabled = allowed
        self.speechTextLabel.text = allowed ? "Tap on Mic button to start recording." : "We do not have permission to access microphone."
    }
    
    private
    func createPulse(power: Float) {
        if power > Constants.lowerLimit && power != 0 {
            let scale: Float = 1.75
            let proportion = scale + scale * (power - Constants.lowerLimit) / Constants.lowerLimit
            
            UIView.animate(withDuration: 0.1, animations: {
                self.wave.transform =  CGAffineTransform(scaleX: CGFloat(scale - proportion), y: CGFloat(scale - proportion))
            })
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                self.wave.transform = .identity
            })
        }
    }
}
