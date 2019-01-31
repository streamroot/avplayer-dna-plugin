Pod::Spec.new do |s|  
    s.name              = 'AVPlayerDNAPlugin'
    s.version           = '1.1.5'
    s.swift_version     = '4.2'
    s.summary           = 'Streamroot Distributed Network Architecture AVPlayer plugins, a new way to deliver large-scale OTT video'
    s.homepage          = 'https://www.streamroot.io/'
    s.author            = { 'Name' => 'support-team@streamroot.io' }
    s.license      = {
        :type => 'Copyright',
        :text => 'Copyright 2018 Streamroot. See the terms of service at https://www.streamroot.io/'
    }
    s.platform          = :ios
    s.source            = { :http => "https://sdk.streamroot.io/ios/AVPlayerDNAPlugin/#{s.version}/AVPlayerDNAPlugin.framework.zip" }
    s.ios.deployment_target = '9.2'
    s.tvos.deployment_target = '10.2'
#     s.source            ={ :git => 'https://github.com/streamroot/avplayer-dna-plugin.git',  :tag => "#{s.version}"}
#     s.source_files = 'PlayerDNAPlugin/Classes/*.swift'
    s.ios.vendored_frameworks = 'Carthage/Build/iOS/AVPlayerDNAPlugin.framework'
    s.tvos.vendored_frameworks = 'Carthage/Build/tvOS/AVPlayerDNAPlugin.framework'
    s.dependency 'StreamrootSDK', '~> 3.10.0'
end