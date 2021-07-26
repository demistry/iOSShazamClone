//
//  ViewController.swift
//  iOSShazamClone
//
//  Created by David Ilenwabor on 26/07/2021.
//

import AVKit
import ShazamKit
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    
    private var session = SHSession()
    private let audioEngine = AVAudioEngine()
    override func viewDidLoad() {
        super.viewDidLoad()
        session.delegate = self
    }

    @IBAction func startListening(_ sender: Any) {
        startRecording()
    }
    
    
    @IBAction func stopListening(_ sender: Any) {
        stopRecording()
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        switch audioSession.recordPermission {
        case .undetermined:
            requestRecordPermission(audioSession: audioSession)
        case .denied:
//            viewState = .recordPermissionSettingsAlert
            print("Permission denied....")
        case .granted:
            DispatchQueue.global(qos: .background).async {
                self.proceedWithRecording()
            }
        @unknown default:
            requestRecordPermission(audioSession: audioSession)
        }
    }
    
    private func requestRecordPermission(audioSession: AVAudioSession) {
        audioSession.requestRecordPermission { [weak self] status in
            DispatchQueue.main.async {
                if status {
                    DispatchQueue.global(qos: .background).async {
                        self?.proceedWithRecording()
                    }
                } else {
                    print("Permission denied")
                }
            }
        }
    }

    private func proceedWithRecording() {
//        DispatchQueue.main.async {
//            self.viewState = .recordingInProgress
//        }

        if audioEngine.isRunning {
            stopRecording()
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: .zero)

        inputNode.removeTap(onBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            print("Current Recording at: \(time)")
            self?.session.matchStreamingBuffer(buffer, at: time)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func stopRecording() {
        audioEngine.stop()
    }
    
}


extension ViewController: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let matchedMediaItem = match.mediaItems.first else {
            return
        }
        stopRecording()
        DispatchQueue.main.async {
            self.songName.text = matchedMediaItem.title
            self.songArtist.text = matchedMediaItem.artist
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        print("Error with finding match \(error?.localizedDescription ?? "")")
        stopRecording()
    }
}
