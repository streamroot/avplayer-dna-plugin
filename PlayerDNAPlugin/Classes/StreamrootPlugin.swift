//
//  StreamrootPlugin.swift
//  Demo
//
//  Created by Lamine Ndiaye on 03/09/2018.
//  Copyright © 2018 Streamroot. All rights reserved.
//
import AVFoundation
import AVKit
import StreamrootSDK

@objc public class DNAConfig: NSObject {
    /// Unique Streamroot Key that we assigned to you,
    /// make sure it's identical to the one provided in the Account section of your dashboard
    // Can be set in the Plist or int the DNAConfig
    public var streamrootKey: String

    /// Identifier used by the Streamroot backend to match peers who watch the same content.
    public var contentId: String?
    /// The differency between current playback time and the live edge
    public var latency: Int?
    /// Used to fine-tune various parameters across all your integrations.
    /// For more information about it, please refer to this https://support.streamroot.io/hc/en-us/articles/360001091914.
    public var property: String?
    /// Used to change the place of the Streamroot backend. You must mention the protocol used, either "HTTP" or "HTTPS".
    public var backendHost: URL?

    public init(streamrootKey: String,
                contentId: String? = nil,
                latency: Int = 0,
                property: String? = nil,
                backendHost: URL? = nil) {
        self.streamrootKey = streamrootKey
        self.contentId = contentId
        self.latency = latency
        self.property = property
        self.backendHost = backendHost
    }
}

/// Streamroot Plugin
public protocol StreamrootPlugin {
    // Optional configurations
    var config: DNAConfig { get set }
    var dnaClient: DNAClient? { get }
    var manifestUrl: URL { get }
    /// Link the plugin to the player
    func linkPlayer(_ player: AVPlayer?) throws
    /// Start the streamroot server
    /// - returns: Local manifest URL
    func start() throws -> URL?
    /// Stop the DNAClient
    func stop()
}
