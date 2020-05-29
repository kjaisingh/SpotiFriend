source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Sample' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpotiFriend
pod 'SpotifyLogin', '~> 0.1'
pod 'Spartan'
pod 'Kingfisher'
pod 'Cosmos'
pod 'SVProgressHUD'
pod 'Charts'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

end
