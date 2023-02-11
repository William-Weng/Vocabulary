//
//  AppDelegate.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/1/21.
//

import UIKit
import AVFAudio
import WWPrint
import WWSQLite3Manager

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var audioPlayer: AVAudioPlayer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        initDatabase()
        backgroundBarColor(UIColor.black.withAlphaComponent(0.1))
        audioInterruptionNotification()
        
        return true
    }
    
    @objc func replayMusic(_ notificaiton: Notification) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let this = self else { return }
            this.audioPlayer?.play()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AppDelegate: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { player.play() }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) { wwPrint(error) }
}

// MARK: - 小工具
extension AppDelegate {
    
    /// 播放背景音樂
    /// - Parameters:
    ///   - music: 音樂檔案
    ///   - volume: 音量大小
    /// - Returns: Bool
    func playBackgroundMusic(with music: Music, volume: Float) -> Bool {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let audioPlayer = musicPlayerMaker(with: music) else { return false }
        
        self.audioPlayer = audioPlayer
        
        audioPlayer.volume = volume
        audioPlayer.play()
                
        return true
    }
    
    /// 取得背景音樂聲音大小
    /// - Returns: Float
    func musicVolume() -> Float? { return audioPlayer?.volume }
    
    /// 設定背景音樂聲音大小
    /// - Parameter volume: Float
    /// - Returns: Float
    func musicVolumeSetting(_ volume: Float) -> Float? {
        Constant.volume = volume + 0.00001
        audioPlayer?.volume = Constant.volume
        return musicVolume()
    }
}

// MARK: - 小工具
private extension AppDelegate {
    
    /// 初始化資料表 / 資料庫
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connent(with: Constant.databaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database):
            
            Constant.database = database
            Constant.VoiceCode.allCases.forEach { _ = createDatabase(database, for: $0) }
            
            wwPrint(database.fileURL)
        }
    }
    
    /// 建立該語言的資料庫群
    /// - Parameters:
    ///   - database: SQLite3Database
    ///   - tableName: Constant.VoiceCode
    /// - Returns: [SQLite3Database.ExecuteResult]
    func createDatabase(_ database: SQLite3Database, for tableName: Constant.VoiceCode) -> [SQLite3Database.ExecuteResult] {
        
        let result = [
            database.create(tableName: tableName.rawValue, type: Vocabulary.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularyList(), type: VocabularyList.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularyReviewList(), type: VocabularyReviewList.self, isOverwrite: false),
            database.create(tableName: tableName.vocabularySentenceList(), type: VocabularySentenceList.self, isOverwrite: false),
        ]
        
        return result
    }
    
    /// 設定Bar的背景色
    /// - Parameter color: UIColor
    func backgroundBarColor(_ color: UIColor) {
        UINavigationBar.appearance()._backgroundColor(color)
        UITabBar.appearance()._backgroundColor(color)
    }
    
    /// 音樂播放器
    /// - Parameter music: Music
    func musicPlayerMaker(with music: Music) -> AVAudioPlayer? {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let audioURL = music.fileURL(),
              let audioPlayer = AVAudioPlayer._build(audioURL: audioURL, fileTypeHint: music.fileType(), delegate: self)
        else {
            return nil
        }
        
        return audioPlayer
    }
    
    /// 註冊音樂被中斷的通知 (Safari播放單字聲音時，音樂會被中斷)
    func audioInterruptionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(Self.replayMusic(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
}

