//
//  AVPlayerPlugin.swift
//  AVPlayerDNAPlugin
//
//  Created by Lamine Ndiaye on 27/10/2018.
//  Copyright © 2018 Streamroot. All rights reserved.
//

import AVFoundation
import AVKit
import StreamrootSDK

@objc public class AVPlayerDNAPlugin: NSObject, StreamrootPlugin {
    public var manifestUrl: URL

    public var config: DNAConfig

    public internal(set) var dnaClient: DNAClient?

    fileprivate var player: AVPlayer?

    fileprivate var observer: Any?

    fileprivate var qosModule: QosModule

    fileprivate var playbackState: PlaybackState

    private var latency: Int {
        return config.latency ?? 0
    }

    /// Plugin constructor
    /// - parameter manifestUrl: the url object of the manifest.
    /// - parameter config: custom configuration
    ///
    public init(manifestUrl: URL, config: DNAConfig) {
        self.manifestUrl = manifestUrl
        self.config = config
        qosModule = DNAQos.module(type: .plugin)
        playbackState = .idle
        super.init()
    }

    /// Start the streamroot server
    /// - returns: Local manifest URL
    public func start() throws -> URL? {
        var builder = DNAClient.builder().dnaClientDelegate(self)
        if let srkey = config.streamrootKey, !srkey.isEmpty {
            builder = builder.streamrootKey(srkey)
        }

        if let latency = config.latency, latency > 0 {
            builder = builder.latency(latency)
        }

        if let backendHost = config.backendHost {
            builder = builder.backendHost(backendHost)
        }

        if let contentId = config.contentId, !contentId.isEmpty {
            builder = try builder.contentId(contentId)
        }

        if let property = config.property, !property.isEmpty {
            builder = builder.property(property)
        }
        builder = builder.qosModule(qosModule)
        dnaClient = try builder.start(manifestUrl)
        guard let manifest = dnaClient?.manifestLocalURLPath else {
            return manifestUrl
        }
        return URL(string: manifest)
    }

    /// Link the plugin to the player
    @objc public func linkPlayer(_ player: AVPlayer?) throws {
        self.player = player
        guard let playerItem = player?.currentItem else { return }

        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayedToEndFail),
                                               name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayToEndSucceded),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAccesLogEntry),
                                               name: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handleErrorLogEntry),
                                               name: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handleItemPlayBackJumped),
                                               name: NSNotification.Name.AVPlayerItemTimeJumped,
                                               object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handleItemPlayBackStall),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: playerItem)
        player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        observePlayback()
    }

    /// Stop the DNAClient
    @objc public func stop() {
        dnaClient?.stop()
        if let observer = self.observer {
            player?.removeTimeObserver(observer)
            self.observer = nil
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                                  object: player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewAccessLogEntry,
                                                  object: player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
                                                  object: player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemTimeJumped,
                                                  object: player?.currentItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                                  object: player?.currentItem)
        player?.removeObserver(self, forKeyPath: "rate")
    }
}

// MARK: - Handler

extension AVPlayerDNAPlugin {
    @objc private func handlePlayedToEndFail(_: Notification) {
        qosModule.playbackErrorOccurred()
    }

    @objc private func handlePlayToEndSucceded(_: Notification) {
        updateState(.ended)
    }

    @objc private func handleAccesLogEntry(_: Notification) {
        guard let playerEvents = player?.currentItem?.accessLog()?.events.first else {
            return
        }
        // trackswitch
        if playerEvents.switchBitrate > 0 {
            qosModule.trackSwitchOccurred()
        }
        // dropframe
        if playerEvents.numberOfDroppedVideoFrames > 0 {
            qosModule.updateDroppedFrameCount(playerEvents.numberOfDroppedVideoFrames)
        }
    }

    @objc private func handleErrorLogEntry(_: Notification) {
        qosModule.playbackErrorOccurred()
    }

    @objc private func handleItemPlayBackJumped(_: Notification) {
        updateState(.seeking)
    }

    @objc private func handleItemPlayBackStall(_: Notification) {
        updateState(.buffering)
    }
}

// MARK: - Helper

extension AVPlayerDNAPlugin {
    fileprivate func observePlayback() {
        if let observer = self.observer {
            player?.removeTimeObserver(observer)
            self.observer = nil
        }

        // Invoke callback every half second
        let interval = CMTime(seconds: 1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        observer = player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] _ in
            guard let self = self else { return }

            let playbackLikelyToKeepUp: Bool = self.player?.currentItem?.isPlaybackLikelyToKeepUp ?? false
            if !playbackLikelyToKeepUp {
                // rebuffering
                self.updateState(.buffering)
            } else {
                // playing
                let rate = self.player?.rate
                if rate == 1.0, self.player?.error == nil {
                    self.updateState(.playing)
                }
            }
        }
    }

    fileprivate func updateState(_ state: PlaybackState) {
        if playbackState != state {
            qosModule.playerStateDidChange(state)
            playbackState = state
        }
    }

    public override func observeValue(forKeyPath keyPath: String?,
                                      of _: Any?,
                                      change _: [NSKeyValueChangeKey: Any]?,
                                      context _: UnsafeMutableRawPointer?) {
        if keyPath == "rate", player?.rate == 0.0 {
            updateState(.paused)
        }
    }
}

// MARK: - DNAClientDelegate

extension AVPlayerDNAPlugin: DNAClientDelegate {
    public func playbackTime() -> Double {
        if let player = self.player {
            return CMTimeGetSeconds(player.currentTime())
        }
        return 0
    }

    public func loadedTimeRanges() -> [NSValue] {
        guard let player = self.player else {
            return []
        }

        guard let playerItem = player.currentItem else {
            return []
        }

        let timeRanges = playerItem.loadedTimeRanges
        return timeRanges.map { (value) -> NSValue in
            NSValue(timeRange: TimeRange(range: value.timeRangeValue))
        }
    }

    public func updatePeakBitRate(_ bitRate: Double) {
        player?.currentItem?.preferredPeakBitRate = bitRate
    }

    public func bufferTarget() -> Double {
        if #available(iOS 10.0, tvOS 10.0, *) {
            return self.player?.currentItem?.preferredForwardBufferDuration ?? 0
        }
        return 0.0
    }

    public func setBufferTarget(_ target: Double) {
        if #available(iOS 10.0, tvOS 10.0, *) {
            self.player?.currentItem?.preferredForwardBufferDuration = target
        }
    }
}
