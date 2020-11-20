# Uncomment the next line to define a global platform for your project
use_frameworks!
inhibit_all_warnings!

workspace 'PlayerDNAPlugin'

def podCommon
  pod 'StreamrootSDK'
end

target 'AVPlayerDNAPlugin-iOS' do
  platform :ios, '10.2'
  podCommon
end

target 'AVPlayerDNAPlugin-tvOS' do
  platform :tvos, '10.2'
  podCommon
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      config.build_settings['ENABLE_BITCODE'] = "YES"
      if config.name == "Debug"
        cflags = config.build_settings['OTHER_CFLAGS'] || ['$(inherited)']
        cflags << '-fembed-bitcode-marker'
        config.build_settings['BITCODE_GENERATION_MODE'] = "marker"
      else 
        cflags = config.build_settings['OTHER_CFLAGS'] || ['$(inherited)']
        cflags << '-fembed-bitcode'
        config.build_settings['BITCODE_GENERATION_MODE'] = "bitcode"
      end
        config.build_settings['OTHER_CFLAGS'] = cflags
    end
  end
end

