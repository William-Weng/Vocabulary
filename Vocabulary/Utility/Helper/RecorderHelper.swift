//
//  RecorderHelper.swift
//  Vocabulary
//
//  Created by William.Weng on 2026/2/12.
//

import Foundation
import AVFAudio

// MARK: - RecorderHelper (單例)
final class RecorderHelper: NSObject {
    
    static let shared = RecorderHelper()
    
    private var recordPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    
    private override init() {}
}

// MARK: - AVAudioRecorderDelegate
extension RecorderHelper: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        guard let recordlayer = AVAudioPlayer._build(audioURL: recorder.url, fileTypeHint: .wav, delegate: nil) else { return }
        
        self.recordPlayer = recordlayer
        recordlayer.play()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { myPrint(error) }
}

// MARK: - 公開函式
extension RecorderHelper {
    
    /// 錄製聲音
    /// - Returns: Bool
    func start() -> Bool {
        guard let recordURL = FileManager.default._temporaryDirectory()._appendPath(Constant.recordFilename) else { return false }
        return recordSound(with: recordURL)
    }
    
    /// 停止錄製聲音
    /// - Returns: Bool
    func stop() -> Bool { stopRecorder() }
}

// MARK: - 小工具
private extension RecorderHelper {
    
    /// 開始錄音 (.wav)
    /// - Parameter recordURL: URL
    /// - Returns: Bool
    func recordSound(with recordURL: URL) -> Bool {
        
        _ = audioRecorder?._stop()
        
        guard let audioRecorder = AVAudioRecorder._build(recordURL: recordURL) else { return false }

        self.audioRecorder = audioRecorder
        audioRecorder.delegate = self
        
        let result = audioRecorder._record()
        
        switch result {
        case .failure(let error): myPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// 停止錄音
    /// - Returns: Bool
    func stopRecorder() -> Bool {
        
        guard let result = audioRecorder?._stop() else { return false }
        
        switch result {
        case .failure(let error): myPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
}
