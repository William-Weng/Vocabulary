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
    
    var musicLoopType: Constant.MusicLoopType = .infinity
    var currentMusic: Music?
    
    private override init() {}
}

// MARK: - WWNormalizeAudioPlayer.Delegate
extension MusicHelper: WWNormalizeAudioPlayer.Deleagte {
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, callbackType: AVAudioPlayerNodeCompletionCallbackType, didFinishPlaying audioFile: AVAudioFile) {
        audioPlayerDidFinishPlayingAction(player)
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, audioFile: AVAudioFile, totalTime: TimeInterval, currentTime: TimeInterval) {
        myPrint("\(currentTime) (\(totalTime))")
    }
    
    func audioPlayer(_ player: WWNormalizeAudioPlayer, error: any Error) {
        myPrint(error)
    }
}

// MARK: - 公開函式
extension MusicHelper {
    
    /// 初始化播放器設定
    func initAudioPlaySetting() {
        
        let options: AVAudioSession.CategoryOptions = [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP]
        
        _ = AVAudioSession.sharedInstance()._setCategory(.playAndRecord, mode: .default, policy: .default, options: options, isActive: true)
        
        audioPlayer.delegate = self
        audioPlayer.preferredFrameRateRange = nil
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
        audioPlayer.volume = volume
        return audioPlayer.volume
    }
    
    /// 播放音樂
    /// - Parameters:
    ///   - music: 音樂檔案
    ///   - volume: 音量大小
    ///   - loopType: MusicLoopType
    /// - Returns: Bool
    func play(music: Music?, volume: Float, musicLoopType: Constant.MusicLoopType) -> Bool {
        
        guard let music = music,
              let audioUrl = music.fileURL()
        else {
            return false
        }
        
        self.currentMusic = music
        self.musicLoopType = musicLoopType
        
        audioPlayer.play(with: audioUrl, targetDB: -5.0)
        audioPlayer.volume = volume
        musicPlayerHint()
        
        return true
    }
    
    /// 停止播放音樂
    @discardableResult
    func stop() -> Bool {
        musicLoopType = .stop
        audioPlayer.stop()
        return true
    }
    
    /// 回復播放音樂
    @discardableResult
    func resume() -> Bool {
        audioPlayer.resume()
        return true
    }
    
    /// 暫停播放音樂
    @discardableResult
    func pause() -> Bool {
        audioPlayer.pause()
        return true
    }
    
    /// 各音樂播放選項的功能
    /// - Parameters:
    ///   - appDelegate: AppDelegate
    ///   - music: Music
    ///   - musicLoopType: Constant.MusicLoopType
    /// - Returns: (isSuccess: Bool, icon: UIImage)
    func itemMenuAction(music: Music, musicLoopType: Constant.MusicLoopType) -> (isSuccess: Bool, icon: UIImage) {
        
        let isSuccess: Bool
        let musicButtonIcon: UIImage
        
        switch musicLoopType {
        case .infinity:
            isSuccess = MusicHelper.shared.play(music: music, volume: Constant.musicVolume, musicLoopType: musicLoopType)
            musicButtonIcon = .music
        case .loop:
            Constant.playingMusicList = Utility.shared.loopMusics()
            isSuccess = MusicHelper.shared.play(music: Constant.playingMusicList._popFirst(), volume: Constant.musicVolume, musicLoopType: musicLoopType)
            musicButtonIcon = .loop
        case .shuffle:
            Constant.playingMusicList = Utility.shared.shuffleMusics()
            isSuccess = MusicHelper.shared.play(music: Constant.playingMusicList.popLast(), volume: Constant.musicVolume, musicLoopType: musicLoopType)
            musicButtonIcon = .shuffle
        case .stop:
            isSuccess = false
            musicButtonIcon = .music
        }
        
        return (isSuccess, musicButtonIcon)
    }
}

// MARK: - 小工具
private extension MusicHelper {
        
    /// 音樂播完後的動作 => 全曲隨機 / 全曲循環
    /// - Parameters:
    ///   - player: AVAudioPlayer
    ///   - flag: Bool
    func audioPlayerDidFinishPlayingAction(_ player: WWNormalizeAudioPlayer) {
        
        switch musicLoopType {
        case .infinity: break
        case .stop: currentMusic = nil
        case .loop: currentMusic = Constant.playingMusicList._popFirst()
        case .shuffle: currentMusic = Constant.playingMusicList.popLast()
        }
        
        if (Constant.playingMusicList.isEmpty) { Constant.playingMusicList = Utility.shared.musicList(for: musicLoopType) }
        _ = play(music: currentMusic, volume: Constant.musicVolume, musicLoopType: musicLoopType)
    }
    
    /// [音樂檔名提示](http://furnacedigital.blogspot.com/2010/12/avfoundation.html)
    /// - Parameter player: WWNormalizeAudioPlayer
    func musicPlayerHint() {
        
        guard let window = Utility.shared.appDelegate?.window,
              let time = audioPlayer.totalTime()._time(unitsStyle: .positional, allowedUnits: [.minute, .second], behavior: .pad),
              let audioFile = audioPlayer.audioFile
        else {
            return
        }
        
        let text = "[\(time)] \(audioFile.url.lastPathComponent)"
        
        WWToast.shared.setting(backgroundViewColor: .black)
        WWToast.shared.makeText(text, targetFrame: window.frame)
    }
}
