//
//  MusicHelper.swift
//  Vocabulary
//
//  Created by William.Weng on 2026/2/12.
//

import UIKit
import AVFAudio
import WWNormalizeAudioPlayer
import WWToast

// MARK: - MusicHelper (單例)
final class MusicHelper: NSObject {
    
    static let shared = MusicHelper()
    
    let audioPlayer: WWNormalizeAudioPlayer = .init()
    
    var tracks: [URL] = []
    var musicLoopType: Constant.MusicLoopType = .infinity
    var trackIndex: Int?
    
    private override init() {}
}

// MARK: - WWNormalizeAudioPlayer.Delegate
extension MusicHelper: WWNormalizeAudioPlayer.Delegate {
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, didStartTracks tracks: [URL], totalDuration: TimeInterval) {
        self.tracks = tracks
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, trackIndex: Int, currentTime: TimeInterval, trackTime: TimeInterval) {
        
        if (self.trackIndex == nil) {
                        
            let track = tracks[trackIndex]
            let time = trackTime._time(unitsStyle: .positional, allowedUnits: [.minute, .second], behavior: .pad) ?? "--:--"
            let hint: String = "\(trackIndex + 1). [\(time)] \(track.lastPathComponent)"
            
            self.trackIndex = trackIndex
            musicPlayerHint(hint)
        }
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, didFinishTrackIndex trackIndex: Int, callbackType: AVAudioPlayerNodeCompletionCallbackType) {
        self.trackIndex = nil
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, error: any Error) {
        musicPlayerHint(error.localizedDescription)
    }
}

// MARK: - 公開函式
extension MusicHelper {
    
    /// 初始化播放器設定
    @MainActor
    func initAudioPlaySetting() {
        audioPlayer.configure(delegate: self, options: [.mixWithOthers])
        audioPlayer.volume = 0.1
    }
    
    /// 取得背景音樂音量大小
    /// - Returns: Float
    func musicVolume() -> Float {
        return audioPlayer.volume
    }
    
    /// 設定背景音樂聲音大小
    /// - Parameter volume: Float
    /// - Returns: Float
    func musicVolumeSetting(_ volume: Float) -> Float {
        
        Constant.musicVolume = volume
        audioPlayer.volume = Constant.musicVolume
        
        return audioPlayer.volume
    }
    
    /// [播放音樂](http://furnacedigital.blogspot.com/2010/12/avfoundation.html)
    /// - Parameters:
    ///   - list: 音樂檔案列表
    ///   - volume: 音量大小
    ///   - loopType: MusicLoopType
    func playMusic(with list: [Music], volume: Float, musicLoopType: Constant.MusicLoopType) async {
        
        guard !list.isEmpty else { return }
        
        let audioUrls = list.compactMap { $0.fileURL() }
        let isShuffle = musicLoopType == .shuffle ? true : false
        
        stop()
        audioPlayer.volume = volume
        self.musicLoopType = musicLoopType

        await audioPlayer.play(with: audioUrls, targetDB: -1.0, loop: true, shuffle: isShuffle)
    }
    
    /// 停止播放音樂
    func stop() {
        trackIndex = nil
        musicLoopType = .stop
        audioPlayer.stop()
    }
    
    /// 回復播放音樂
    @MainActor
    func resume() {
        audioPlayer.resume()
    }
    
    /// 暫停播放音樂
    func pause() {
        audioPlayer.pause()
    }
}

// MARK: - 小工具
private extension MusicHelper {
    
    /// [音樂檔名提示](http://furnacedigital.blogspot.com/2010/12/avfoundation.html)
    /// - Parameter hint: 提示文字
    @MainActor
    func musicPlayerHint(_ hint: String) {
        
        guard let window = Utility.shared.appDelegate?.window else { return }
        
        WWToast.shared.setting(backgroundViewColor: .black)
        WWToast.shared.makeText(hint, targetFrame: window.frame)
    }
}
