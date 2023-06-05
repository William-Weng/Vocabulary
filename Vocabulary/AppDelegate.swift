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
import WWNetworking_UIImage

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private let audioPlayerQueue = DispatchQueue(label: "github.com/William-Weng/Vocabulary")
    
    private var audioPlayer: AVAudioPlayer?
    private var recordlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        _ = WWWebImage.initDatabase(for: .caches, expiredDays: 90)
        initDatabase()
        backgroundBarColor(.black.withAlphaComponent(0.1))
        audioInterruptionNotification()
        
        _ = animationFolderUrlMaker()
        
        return true
    }
    
    @objc func replayMusic(_ notificaiton: Notification) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let this = self else { return }
            this.audioPlayer?._play(queue: this.audioPlayerQueue)
        }
    }
    
    deinit { wwPrint("\(Self.self) deinit") }
}

// MARK: - AVAudioRecorderDelegate
extension AppDelegate: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        guard let recordlayer = AVAudioPlayer._build(audioURL: recorder.url, fileTypeHint: .wav, delegate: nil) else { return }
        
        self.recordlayer = recordlayer
        recordlayer.play()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { wwPrint(error) }
}

// MARK: - 小工具
extension AppDelegate {
    
    /// 初始化資料表 / 資料庫
    func initDatabase() {
        
        let result = WWSQLite3Manager.shared.connent(for: .documents, filename: Constant.databaseName)
        
        switch result {
        case .failure(_): Utility.shared.flashHUD(with: .fail)
        case .success(let database):
            
            Constant.database = database
            Constant.VoiceCode.allCases.forEach { _ = createDatabase(database, for: $0) }
            
            wwPrint(database.fileURL)
        }
    }
    
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
        audioPlayer.numberOfLoops = -1
        audioPlayer.prepareToPlay()
        audioPlayer._play(queue: audioPlayerQueue)
        
        return true
    }
    
    /// 取得背景音樂音量大小
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
    
    /// 錄製聲音
    func recordWave() -> Bool {
        guard let recordURL = FileManager.default._temporaryDirectory()._appendPath("record.wav") else { return false }
        return recordSound(recordURL: recordURL)
    }
    
    /// 停止錄製聲音
    /// - Returns: Bool
    func stopRecordingWave() -> Bool { stopRecorder() }
}

// MARK: - 小工具
private extension AppDelegate {
    
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
            database.create(tableName: tableName.bookmarks(), type: BookmarkSite.self, isOverwrite: false),
        ]
        
        return result
    }
    
    /// 建立存放GIF動畫的資料夾
    /// - Returns: 資料夾的URL
    func animationFolderUrlMaker() -> URL? {
        
        guard let musicFolderUrl = Constant.FileFolder.animation.url() else { return nil }
        
        let result = FileManager.default._createDirectory(with: musicFolderUrl, path: "")
        
        switch result {
        case .failure(let error): wwPrint(error); return nil
        case .success(let isSuccess): return (!isSuccess) ? nil : musicFolderUrl
        }
    }
    
    /// 設定Bar的背景色
    /// - Parameter color: UIColor
    func backgroundBarColor(_ color: UIColor) {
        UINavigationBar.appearance()._backgroundColor(color)
        UITabBar.appearance()._backgroundColor(color)
    }
    
    /// 音樂播放器
    /// - Parameter music: Music
    /// - Returns: AVAudioPlayer?
    func musicPlayerMaker(with music: Music) -> AVAudioPlayer? {
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let audioURL = music.fileURL(),
              let audioPlayer = AVAudioPlayer._build(audioURL: audioURL, fileTypeHint: music.fileType(), delegate: nil)
        else {
            return nil
        }
        
        return audioPlayer
    }
    
    /// 註冊音樂被中斷的通知 (Safari播放單字聲音時，音樂會被中斷)
    func audioInterruptionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(Self.replayMusic(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    /// 開始錄音 (.wav)
    /// - Parameter recordURL: URL
    /// - Returns: Bool
    func recordSound(recordURL: URL) -> Bool {
        
        _ = audioRecorder?._stop()
        
        guard let audioRecorder = AVAudioRecorder._build(recordURL: recordURL) else { return false }

        self.audioRecorder = audioRecorder
        audioRecorder.delegate = self
        
        let result = audioRecorder._record()
        
        switch result {
        case .failure(let error): wwPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
    
    /// 停止錄音
    /// - Returns: Bool
    func stopRecorder() -> Bool {
        
        guard let result = audioRecorder?._stop() else { return false }
        
        switch result {
        case .failure(let error): wwPrint(error); return false
        case .success(let isSuccess): return isSuccess
        }
    }
}


