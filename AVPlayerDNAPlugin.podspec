Pod::Spec.new do |s|  
    s.name              = 'AVPlayerDNAPlugin'
    s.version           = '1.1.23'
    s.swift_version     = '5.3'
    s.summary           = 'Streamroot Distributed Network Architecture AVPlayer plugins, a new way to deliver large-scale OTT video'
    s.homepage          = 'https://www.streamroot.io/'
    s.author            = { 'Name' => 'support-team@streamroot.io' }
    s.license      = {
        :type => 'Copyright',
        :text => 'Copyright 2020 Streamroot. See the terms of service at https://www.streamroot.io/'
    }
    s.platform          = :ios
    s.source            ={ :git => 'https://github.com/streamroot/avplayer-dna-plugin.git',  :tag => "#{s.version}"}
    s.source_files = 'PlayerDNAPlugin/Classes/*.swift'
    s.ios.deployment_target = '10.2'
    s.tvos.deployment_target = '10.2'
    s.dependency 'StreamrootSDK', '~> 3.23.1'
    s.pod_target_xcconfig = { 'VALID_ARCHS' => 'x86_64 armv7 arm64' }
end